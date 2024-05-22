#pragma once

#include <Poco/JSON/Object.h>

#include <optional>
#include <string>
#include <vector>

namespace database {
class Service {
private:
    std::string _id;
    std::string _name;
    double _price;

public:
    static const std::string collection;

    Service() = default;
    Service(std::string id)
        : _id(id) {}
    Service(std::string id, std::string name, double price)
        : _id(id), _name(name), _price(price) {}

    static Service fromJSON(const std::string& str);

    const std::string& get_id() const { return _id; };
    const std::string& get_name() const { return _name; };
    double get_price() const { return _price; };

    std::string& id() { return _id; };
    std::string& name() { return _name; };
    double& price() { return _price; };

    bool check_price(std::string& reason);

    static std::optional<Service> get_by_id(std::string id);
    static std::vector<Service> get_all();
    // static std::vector<Service> search_by_name(std::string name);
    static bool remove(std::string id);
    void update();
    void save();

    Poco::JSON::Object::Ptr toJSON() const;
};
}
