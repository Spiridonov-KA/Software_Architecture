#include "service_handler.h"

#include <Poco/Exception.h>
#include <Poco/Net/HTMLForm.h>
#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>
#include <Poco/URI.h>

#include <fstream>
#include <iostream>
#include <string>

#include "../../database/mongodb.h"
#include "../../database/service.h"

void ServiceHandler::handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response) {
    Poco::Net::HTMLForm form(request, request.stream());
    Poco::URI uri(request.getURI());

    response.setChunkedTransferEncoding(true);
    response.setContentType("application/json");

    try {
        if (uri.getPath() == "/service") {
            if (request.getMethod() == Poco::Net::HTTPRequest::HTTP_GET) {
                std::string id = form.get("id");

                std::optional<database::Service> result = database::Service::get_by_id(id);
                if (result) {
                    response.setStatus(Poco::Net::HTTPResponse::HTTP_OK);
                    std::ostream& ostr = response.send();
                    Poco::JSON::Stringifier::stringify(result->toJSON(), ostr);
                    return;
                } else {
                    response.setStatus(Poco::Net::HTTPResponse::HTTPStatus::HTTP_NOT_FOUND);
                    Poco::JSON::Object::Ptr root = new Poco::JSON::Object();
                    root->set("status", static_cast<int>(response.getStatus()));
                    root->set("detail", "service not found");
                    root->set("instance", uri.getPath());
                    std::ostream& ostr = response.send();
                    Poco::JSON::Stringifier::stringify(root, ostr);
                    return;
                }
            } else if (request.getMethod() == Poco::Net::HTTPRequest::HTTP_POST) {
                std::string message;
                if (form.has("name") && form.has("price")) {
                    database::Service service(database::mongodb::getId());
                    service.name() = form.get("name");
                    service.price() = std::stod(form.get("price"));

                    bool valid_request = true;
                    std::string reason;

                    if (!service.check_price(reason)) {
                        valid_request = false;
                        message += reason;
                        message += "\n";
                    }

                    if (valid_request) {
                        service.save();
                        response.setStatus(Poco::Net::HTTPResponse::HTTP_OK);
                        std::ostream& ostr = response.send();
                        Poco::JSON::Stringifier::stringify(service.toJSON(), ostr);
                        return;
                    }
                }

                if (message.empty()) {
                    message = "service information is incomplete";
                }

                response.setStatus(Poco::Net::HTTPResponse::HTTPStatus::HTTP_BAD_REQUEST);
                Poco::JSON::Object::Ptr root = new Poco::JSON::Object();
                root->set("status", static_cast<int>(response.getStatus()));
                root->set("detail", message);
                root->set("instance", uri.getPath());
                std::ostream& ostr = response.send();
                Poco::JSON::Stringifier::stringify(root, ostr);
                return;
            } else if (request.getMethod() == Poco::Net::HTTPRequest::HTTP_PUT) {
                std::string id = form.get("id");

                std::optional<database::Service> result = database::Service::get_by_id(id);
                if (result) {
                    database::Service& service = result.value();
                    service.name() = form.get("name", service.name());
                    service.price() = std::stod(form.get("price"));

                    bool valid_request = true;
                    std::string reason, message;

                    if (!service.check_price(reason)) {
                        valid_request = false;
                        message += reason;
                        message += "\n";
                    }

                    if (valid_request) {
                        service.save();
                        response.setStatus(Poco::Net::HTTPResponse::HTTP_OK);
                        std::ostream& ostr = response.send();
                        Poco::JSON::Stringifier::stringify(service.toJSON(), ostr);
                        return;
                    }

                    response.setStatus(Poco::Net::HTTPResponse::HTTPStatus::HTTP_BAD_REQUEST);
                    Poco::JSON::Object::Ptr root = new Poco::JSON::Object();
                    root->set("status", static_cast<int>(response.getStatus()));
                    root->set("detail", message);
                    root->set("instance", uri.getPath());
                    std::ostream& ostr = response.send();
                    Poco::JSON::Stringifier::stringify(root, ostr);
                    return;
                }

                response.setStatus(Poco::Net::HTTPResponse::HTTPStatus::HTTP_NOT_FOUND);
                Poco::JSON::Object::Ptr root = new Poco::JSON::Object();
                root->set("status", static_cast<int>(response.getStatus()));
                root->set("detail", "service not found");
                root->set("instance", uri.getPath());
                std::ostream& ostr = response.send();
                Poco::JSON::Stringifier::stringify(root, ostr);
                return;
            } else if (request.getMethod() == Poco::Net::HTTPRequest::HTTP_DELETE) {
                std::string id = form.get("id");

                if (database::Service::remove(id)) {
                    response.setStatus(Poco::Net::HTTPResponse::HTTP_OK);
                    response.send();
                    return;
                } else {
                    response.setStatus(Poco::Net::HTTPResponse::HTTPStatus::HTTP_NOT_FOUND);
                    Poco::JSON::Object::Ptr root = new Poco::JSON::Object();
                    root->set("status", static_cast<int>(response.getStatus()));
                    root->set("detail", "service not found");
                    root->set("instance", uri.getPath());
                    std::ostream& ostr = response.send();
                    Poco::JSON::Stringifier::stringify(root, ostr);
                    return;
                }
            }
        } else if (uri.getPath() == "/service/all" && request.getMethod() == Poco::Net::HTTPRequest::HTTP_GET) {
            std::vector<database::Service> services = database::Service::get_all();
            Poco::JSON::Array result;
            for (auto s : services) {
                result.add(s.toJSON());
            }
            response.setStatus(Poco::Net::HTTPResponse::HTTP_OK);
            std::ostream& ostr = response.send();
            Poco::JSON::Stringifier::stringify(result, ostr);
            return;
        }
    } catch (Poco::NotFoundException& e) {
        response.setStatus(Poco::Net::HTTPResponse::HTTPStatus::HTTP_BAD_REQUEST);
        Poco::JSON::Object::Ptr root = new Poco::JSON::Object();
        root->set("status", static_cast<int>(response.getStatus()));
        root->set("detail", "request is incomplete");
        root->set("instance", uri.getPath());
        std::ostream& ostr = response.send();
        Poco::JSON::Stringifier::stringify(root, ostr);
    } catch (...) {
        response.setStatus(Poco::Net::HTTPResponse::HTTPStatus::HTTP_INTERNAL_SERVER_ERROR);
        Poco::JSON::Object::Ptr root = new Poco::JSON::Object();
        root->set("status", static_cast<int>(response.getStatus()));
        root->set("detail", "internal error");
        root->set("instance", uri.getPath());
        std::ostream& ostr = response.send();
        Poco::JSON::Stringifier::stringify(root, ostr);
    }

    response.setStatus(Poco::Net::HTTPResponse::HTTPStatus::HTTP_NOT_FOUND);
    Poco::JSON::Object::Ptr root = new Poco::JSON::Object();
    root->set("status", static_cast<int>(response.getStatus()));
    root->set("detail", "request not found");
    root->set("instance", uri.getPath());
    std::ostream& ostr = response.send();
    Poco::JSON::Stringifier::stringify(root, ostr);
}