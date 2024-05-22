#include "service.h"

#include <Poco/JSON/Object.h>
#include <Poco/JSON/Parser.h>

#include <optional>
#include <string>
#include <vector>

#include "mongodb.h"

using database::mongodb::Database;

namespace database {
const std::string Service::collection = "services";

Service Service::fromJSON(const std::string& str) {
    Service service;
    Poco::JSON::Parser parser;
    Poco::Dynamic::Var result = parser.parse(str);
    Poco::JSON::Object::Ptr object = result.extract<Poco::JSON::Object::Ptr>();

    service.id() = object->getValue<std::string>("_id");
    service.name() = object->getValue<std::string>("name");
    service.price() = object->getValue<double>("price");

    return service;
}

bool Service::check_price(std::string& reason) {
    if (_price < 0) {
        reason = "Price must be above zero";
        return false;
    }
    return true;
}

std::optional<Service> Service::get_by_id(std::string id) {
    std::optional<std::string> result = Database::get().select(collection, id);
    if (result) {
        return {fromJSON(result.value())};
    }
    return {};
}

std::vector<Service> Service::get_all() {
    std::vector<Service> result;
    Poco::MongoDB::Document selector;
    for (auto& str : Database::get().select(collection, selector)) {
        result.push_back(fromJSON(str));
    }
    return result;
}

// std::vector<Service> Service::search_by_name(std::string name) {
//     return std::vector<Service>();
// }

bool Service::remove(std::string id) {
    return Database::get().remove(collection, id);
}

void Service::update() {
    Database::get().update(collection, _id, toJSON());
}

void Service::save() {
    Database::get().save(collection, toJSON());
}

Poco::JSON::Object::Ptr Service::toJSON() const {
    Poco::JSON::Object::Ptr root = new Poco::JSON::Object();

    root->set("_id", _id);
    root->set("name", _name);
    root->set("price", _price);

    return root;
}
}  // namespace database
