#include "order.h"

#include <Poco/JSON/Object.h>
#include <Poco/JSON/Parser.h>

#include <optional>
#include <string>
#include <vector>
#include <algorithm> 

#include "mongodb.h"
#include "service.h"

using database::mongodb::Database;

namespace database {
const std::string Order::collection = "orders";

Order Order::fromJSON(const std::string& str) {
    Order order;
    Poco::JSON::Parser parser;
    Poco::Dynamic::Var result = parser.parse(str);
    Poco::JSON::Object::Ptr object = result.extract<Poco::JSON::Object::Ptr>();
    order.id() = object->getValue<std::string>("_id");
    for (auto& var: *object->getArray("services")) {
        order.services().push_back(var.extract<std::string>());
    }
    return order;
}

std::optional<Order> Order::get_by_id(std::string id) {
    std::optional<std::string> result = Database::get().select(collection, id);
    if (result) {
        return {fromJSON(result.value())};
    }
    return {};
}

void Order::create(std::string id) {
    Database::get().save(collection, Order(id).toJSON());
}

bool Order::remove(std::string id) {
    return Database::get().remove(collection, id);
}

void Order::add_service(std::string id) {
    _services.push_back(id);
    Poco::JSON::Object::Ptr push = new Poco::JSON::Object(), element = new Poco::JSON::Object();
    element->set("services", id);
    push->set("$push", element);
    Database::get().update(collection, _id, push);
}

bool Order::remove_service(std::string id) {
    bool deleted = false;
    for (auto it = _services.begin(); it != _services.end(); ++it) {
        if (*it == id) {
            deleted = true;
            _services.erase(it);
            break;
        }
    }
    if (deleted) {
        Database::get().update(collection, _id, toJSON());
    }
    return deleted;
}

Poco::JSON::Object::Ptr Order::toJSON() const {
    Poco::JSON::Object::Ptr root = new Poco::JSON::Object();

    root->set("_id", _id);
    Poco::JSON::Array::Ptr services = new Poco::JSON::Array();
    for (auto service: _services) {
        services->add(service);
    }
    root->set("services", services);

    return root;
}
}