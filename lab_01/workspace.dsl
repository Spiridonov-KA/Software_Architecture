workspace main_model "Сайт заказа услуг" {
    name "Где это используется?!"
    model {
        my_user = person "Пользователь, желающий приобрести услугу"

        web_app = softwareSystem "Web приложение" {
            description "Web приложение, отображающее доступные услуги и информацию о них"
        }

        control_system = softwareSystem "Система мониторинга услуг" {
            description "Система для отслеживания доступных услуг"
        }

        pay_system = softwareSystem "Платёжная система" {
            description "Управляет денежными операциями между пользователем и сервисом, предоставляющем услуги"
        }

        service = element "Сервисный центр"

        my_user -> web_app "Заказ услуг"
        web_app -> pay_system "Регистрация платежей" "REST HTTP:443"
        web_app -> control_system "Поиск подходящей услуги и её регистрация" "REST HTTP:443"
        control_system -> service "Бронирование услуги в сервисном центре" "REST HTTP:443"
        service -> my_user "Предоставление услуги"
    }
    views {

        systemLandscape my_user {
            include *
            autoLayout
        }

        systemContext web_app {
            include *
            autoLayout
        }

        systemContext control_system {
            include *
            autoLayout
        }

        themes default
    }
}
