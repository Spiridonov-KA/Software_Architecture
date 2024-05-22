#pragma once

#include <Poco/JSON/Object.h>

#include <optional>
#include <string>
#include <vector>

#include "service.h"

namespace database {
class Order {
private:
    std::string _id;
    std::vector<std::string> _services;

public:
    static const std::string collection;

    Order() = default;
    Order(std::string id)
        : _id(id) {}

    static Order fromJSON(const std::string& str);

    const std::string& get_id() const { return _id; };
    const std::vector<std::string>& get_services() const { return _services; };

    std::string& id() { return _id; };
    std::vector<std::string>& services() { return _services; };

    static std::optional<Order> get_by_id(std::string id);
    static void create(std::string id);
    static bool remove(std::string id);
    void add_service(std::string id);
    bool remove_service(std::string id);

    Poco::JSON::Object::Ptr toJSON() const;
};
}
