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
        

        service = element "Сервисный центр"

        web_app = softwareSystem "Web Application" {
            description "Web приложение, по поиску и размещения услуг"

            user_service = container "User Service" {
                description "Сервис управления пользователями"
            }

            executor_service = container "Executor Service" {
                description "Сервис упраления услугами"
            }

            group "Слой данных" {
                user_database = container "User Database" {
                    description "База данных с пользователями"
                    technology "PostgreSQL 15"
                    tags "database"
                }

                executor_database = container "Executor Database" {
                    description "База данных с информацией об услугах"
                    technology "MongoDB 5"
                    tags "database"
                }

                user_cache = container "User Cache" {
                    description "Кэш пользовательских данных для ускорения аунтификации"
                    technology "Redis"
                    tags "database"
                }
            }

            user -> user_service "Поиск подходящей услуги" "TCP 6379"
            user_service -> user_database "Получение/обновление данных о пользователях" "TCP 6379"
            user_service -> executor_service "Получение/обновление данных о доступных услугах" "TCP 6379"
            user_service -> user_cache "Получение/обновление данных о пользователях" "TCP 6379"
            executor_service -> executor_database "Получение/обновление данных о доступных услугах" "TCP 6379"
            executor_service -> service "Запрос на предостваление услуги"
            service -> executor_service "Ответ на запрос"
        }

        user -> web_app "Заказ услуг"
        web_app -> service "Бронирование услуги в сервисном центре" "REST HTTP:443"
        service -> user "Предоставление услуги"

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
                containerInstance web_app.executor_service
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

                deploymentNode "Database Executer" {
                    containerInstance web_app.executor_database
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


        dynamic web_app "UC01" "Процесс отправки формирования информации о запрашиваемой услуге" {
            autoLayout
            user -> web_app.user_service "Пользователь выбирает услугу"
            web_app.user_service -> web_app.user_database "Получение/Добавление информации о пользователе"
            web_app.user_service -> web_app.executor_service "Информация о необходимой услуге"
        }

        dynamic web_app "UC02" "Процесс поиска услуг" {
            autoLayout
            web_app.user_service -> web_app.executor_service "Информация о необходимой услуге"
            web_app.executor_service -> web_app.executor_database "Поиск подходящих услуг"
        }

        dynamic web_app "UC03" "Общая схема работы" {
            autoLayout
            user -> web_app.user_service "Пользователь выбирает услугу"
            web_app.user_service -> web_app.user_database "Получение/Добавление информации о пользователе"
            web_app.user_service -> web_app.executor_service "Информация о необходимой услуге"
            web_app.executor_service -> web_app.executor_database "Поиск подходящих услуг"
            web_app.executor_service -> service "Обращение в центр услуг для подтверждения заказа"
            service -> web_app.executor_service "Ответ на запрос"
            web_app.executor_service -> web_app.executor_database "Занесение информации по услуге"
            service -> user "Исполнение заказа"
        }

    }
}
