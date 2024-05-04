workspace main_model "Сайт заказа услуг" {
    name "Бронирование услуг"
    description "Система по созданию и оказанию услуг"

    !identifiers hierarchical

    !docs documentation
    !adrs decisions

    model {
        properties { 
            structurizr.groupSeparator "/"
        }

        user = person "Пользователь, желающий приобрести услугу"
        
        performer = person "Сервисный центр"

        web_app = softwareSystem "Сайт заказа услуг" {
            description "Web приложение, по поиску и размещения услуг"

            user_service = container "User Service" {
                description "Сервис управления пользователями"
            }

            performer_service = container "Performer Service" {
                description "Сервис упраления услугами"
            }

            order_service = container "Order Service" {
                description "Сервис управления заказами"
            }

            group "Слой данных" {
                user_database = container "User Database" {
                    description "База данных с пользователями"
                    technology "PostgreSQL 15"
                    tags "database"
                }

                performer_database = container "Performer Database" {
                    description "База данных с информацией об услугах"
                    technology "MongoDB 5"
                    tags "database"
                }

                order_database = container "Order Database" {
                    description "База данных с информацией о заказах пользователей"
                    technology "MongoDB 5"
                    tags "database"
                }

                user_cache = container "User Cache" {
                    description "Кэш пользовательских данных для ускорения аунтификации"
                    technology "Redis"
                    tags "database"
                }
            }

            user -> user_service "Поиск подходящей услуги"
            user -> performer_service "Получение списка услуг"
            user -> order_service "Создание заказа"
            user_service -> user_database "Получение/обновление данных о пользователях"
            # user_service -> performer_service "Получение/обновление данных о доступных услугах"
            user_service -> user_cache "Получение/обновление данных о пользователях"
            order_service -> user_service "Получить информацию о пользователе"
            order_service -> performer_service "Получить информацию о сервисе"
            order_service -> order_database "Добавить заказ"
            performer_service -> performer_database "Получение/обновление данных о доступных услугах" "TCP 6379"
            performer_service -> performer "Запрос на предостваление услуги"
            performer -> performer_service "Ответ на запрос"
            performer -> user_service "Запрос информации о пользователях"
        }

        user -> web_app "Заказ услуг"
        web_app -> performer "Бронирование услуги в сервисном центре" "REST HTTP:443"
        performer -> user "Предоставление услуги"

        deploymentEnvironment "Production" {
            deploymentNode "User Server" {
                containerInstance web_app.user_service
                properties {
                    "cpu" "16"
                    "ram" "512Gb"
                    "ssd" "4Tb"
                }
            }

            deploymentNode "Temperature Server" {
                containerInstance web_app.performer_service
                properties {
                    "cpu" "16"
                    "ram" "512Gb"
                    "ssd" "4Tb"
                }
            }

            deploymentNode "databases" {
     
                deploymentNode "Database User" {
                    containerInstance web_app.user_database
                    instances 3
                }

                deploymentNode "Database Performer" {
                    containerInstance web_app.performer_database
                    instances 3
                }

                deploymentNode "Cache User" {
                    containerInstance web_app.user_cache
                    instances 3
                }
            }
        }
    }


    views {

        themes default

        !script groovy {
            workspace.views.createDefaultViews()
            workspace.views.views.findAll { it instanceof com.structurizr.view.ModelView }.each { it.enableAutomaticLayout() }
        }

        properties { 
            structurizr.tooltips true
        }

        dynamic web_app "UC01" "Создание нового пользователя" {
             autoLayout
            user -> web_app.user_service "Создать нового пользователя (POST /user)"
            web_app.user_service -> web_app.user_database "Сохранить данные о пользователе"
        }

        dynamic web_app "UC02" "Поиск пользователя по логину" {
            autoLayout
            performer -> web_app.user_service "Получить пользователя с нужным логином (GET /user/search_by_login)"
            web_app.user_service -> web_app.user_database "Получить данные о пользователе"
        }

        dynamic web_app "UC03" "Поиск пользователя по маске имя и фамилия" {
            autoLayout
            performer -> web_app.user_service "Получить пользователя по маске имени (GET /user/search_by_name)"
            web_app.user_service -> web_app.user_database "Получить данные о пользователях"
        }

        dynamic web_app "UC04" "Создание услуги" {
            autoLayout
            performer -> web_app.performer_service "Создать новую услугу (POST /performer)"
            web_app.performer_service -> web_app.performer_database "Сохранить данные об услуге"
        }

        dynamic web_app "UC05" "Получение списка услуг" {
            autoLayout
            user -> web_app.performer_service "Запрос на список услуг (GET /performer)"
            web_app.performer_service -> web_app.performer_database "Получить информацию по услугам"
        }

        dynamic web_app "UC06" "Добавление услуг в заказ" {
            autoLayout
            user -> web_app.order_service "Запросить добавление услуги в заказ (PUT /order)"
            web_app.order_service -> web_app.user_service "Получить информацию о пользователе"
            web_app.order_service -> web_app.performer_service "Получить информацию об услуге"
            web_app.order_service -> web_app.order_database "Добавить заказ"
        }

        dynamic web_app "UC07" "Получение заказа для пользователя" {
            autoLayout
            user -> web_app.order_service "Запросить информацию о заказе (GET /order)"
            web_app.order_service -> web_app.order_database "Получить информацию о заказе"
        }

        // dynamic web_app "UC01" "Процесс отправки формирования информации о запрашиваемой услуге" {
        //     autoLayout
        //     user -> web_app.user_service "Пользователь выбирает услугу"
        //     web_app.user_service -> web_app.user_database "Получение/Добавление информации о пользователе"
        //     web_app.user_service -> web_app.performer_service "Информация о необходимой услуге"
        // }

        // dynamic web_app "UC02" "Процесс поиска услуг" {
        //     autoLayout
        //     web_app.user_service -> web_app.performer_service "Информация о необходимой услуге"
        //     web_app.performer_service -> web_app.performer_database "Поиск подходящих услуг"
        // }

        // dynamic web_app "UC03" "Создание нового пользователя" {
        //     autoLayout
        //     user -> web_app.user_service "Пользователь задаёт свои данные (POST /user)"
        //     web_app.user_service -> web_app.user_database "Поиск в БД пользователя с заданной почтой и логином"
        //     web_app.user_database -> web_app.user_service "Если почта и логин не заняты возвращатеся, то пользователь добавляется в БД и возвращается код успеха. Иначе возвращается код неуспеха"
        //     web_app.user_service -> user "Успешная регистрация или просит поменять логин или почту"
        // }

        // dynamic web_app "UC04" "Поиск пользователя по логину" {
        //     autoLayout
        //     performer -> web_app.performer_service "Получить пользователя с нужным логином (GET /user)"
        //     web_app.performer_service -> web_app.user_service "Перенаправляет запрос на User Service"
        //     web_app.user_service -> web_app.user_database "Поиск в БД пользователя с заданным логином"
        //     web_app.user_database -> web_app.user_service "Результат поиска"
        //     web_app.user_service -> web_app.performer_service "Результат поиска"
        //     web_app.performer_service -> performer "Результат поиска"
        // }

        // dynamic web_app "UC05" "Поиск пользователя по маске имя и фамилия" {
        //     autoLayout
        //     performer -> web_app.performer_service "Получить пользователя с нужным именем и фамилией (GET /user)"
        //     web_app.performer_service -> web_app.user_service "Перенаправляет запрос на User Service"
        //     web_app.user_service -> web_app.user_database "Поиск в БД пользователя с заданным логином"
        //     web_app.user_database -> web_app.user_service "Результат поиска"
        //     web_app.user_service -> web_app.performer_service "Результат поиска"
        //     web_app.performer_service -> performer "Результат поиска"
        // }

        // dynamic web_app "UC06" "Создание услуги" {
        //     autoLayout
        //     performer -> web_app.performer_service "Добавить новую услугу (POST /Performer)"
        //     web_app.performer_service -> web_app.performer_database "Добавить информацию о новой услуге"
        // }

        // dynamic web_app "UC07" "Добавлене услуги в заказ" {
        //     autoLayout
        //     user -> web_app.user_service "Добавить в заказ услугу (POST /user/order)"
        //     web_app.user_service -> web_app.performer_service "Получить информацию о текущем состоянии услуги"
        //     web_app.performer_service -> web_app.performer_database "Получить информацию о текущем состоянии услуги"
        //     web_app.performer_database -> web_app.performer_service "Информация по услуге"
        //     web_app.performer_service -> web_app.user_service "Информация по услуге"
        //     web_app.user_service -> web_app.user_database "Если услуга доступна, то добавить заказ"
        //     web_app.user_service -> user "Статус заказа: Добавлен/Недоступен"
        // }

        // dynamic web_app "UC08" "Получение заказа для пользователя" {
        //     autoLayout
        //     user -> web_app.user_service "Пользователь выбирает услугу"
        //     web_app.user_service -> web_app.user_database "Получение/Добавление информации о пользователе"
        //     web_app.user_service -> web_app.performer_service "Информация о необходимой услуге"
        //     web_app.performer_service -> web_app.performer_database "Поиск подходящих услуг"
        //     web_app.performer_service -> performer "Обращение в центр услуг для подтверждения заказа"
        //     performer -> web_app.performer_service "Ответ на запрос"
        //     web_app.performer_service -> web_app.performer_database "Занесение информации по услуге"
        //     performer -> user "Исполнение заказа"
        // }

    }
}
