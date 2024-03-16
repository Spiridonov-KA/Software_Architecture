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
        
        executor = person "Сервисный центр"

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
            executor_service -> executor "Запрос на предостваление услуги"
            executor -> executor_service "Ответ на запрос"
        }

        user -> web_app "Заказ услуг"
        web_app -> executor "Бронирование услуги в сервисном центре" "REST HTTP:443"
        executor -> user "Предоставление услуги"

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

                deploymentNode "Database executor" {
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

        dynamic web_app "UC03" "Создание нового пользователя" {
            autoLayout
            user -> web_app.user_service "Пользователь задаёт свои данные (POST /user)"
            web_app.user_service -> web_app.user_database "Поиск в БД пользователя с заданной почтой и логином"
            web_app.user_database -> web_app.user_service "Если почта и логин не заняты возвращатеся, то пользователь добавляется в БД и возвращается код успеха. Иначе возвращается код неуспеха"
            web_app.user_service -> user "Успешная регистрация или просит поменять логин или почту"
        }

        dynamic web_app "UC04" "Поиск пользователя по логину" {
            autoLayout
            executor -> web_app.executor_service "Получить пользователя с нужным логином (GET /user)"
            web_app.executor_service -> web_app.user_service "Перенаправляет запрос на User Service"
            web_app.user_service -> web_app.user_database "Поиск в БД пользователя с заданным логином"
            web_app.user_database -> web_app.user_service "Результат поиска"
            web_app.user_service -> web_app.executor_service "Результат поиска"
            web_app.executor_service -> executor "Результат поиска"
        }

        dynamic web_app "UC05" "Поиск пользователя по маске имя и фамилия" {
            autoLayout
            executor -> web_app.executor_service "Получить пользователя с нужным именем и фамилией (GET /user)"
            web_app.executor_service -> web_app.user_service "Перенаправляет запрос на User Service"
            web_app.user_service -> web_app.user_database "Поиск в БД пользователя с заданным логином"
            web_app.user_database -> web_app.user_service "Результат поиска"
            web_app.user_service -> web_app.executor_service "Результат поиска"
            web_app.executor_service -> executor "Результат поиска"
        }

        dynamic web_app "UC06" "Создание услуги" {
            autoLayout
            executor -> web_app.executor_service "Добавить новую услугу (POST /executor)"
            web_app.executor_service -> web_app.executor_database "Добавить информацию о новой услуге"
        }

        dynamic web_app "UC07" "Добавлене услуги в заказ" {
            autoLayout
            user -> web_app.user_service "Добавить в заказ услугу (POST /user/order)"
            web_app.user_service -> web_app.executor_service "Получить информацию о текущем состоянии услуги"
            web_app.executor_service -> web_app.executor_database "Получить информацию о текущем состоянии услуги"
            web_app.executor_database -> web_app.executor_service "Информация по услуге"
            web_app.executor_service -> web_app.user_service "Информация по услуге"
            web_app.user_service -> web_app.user_database "Если услуга доступна, то добавить заказ"
            web_app.user_service -> user "Статус заказа: Добавлен/Недоступен"
        }

        dynamic web_app "UC08" "Получение заказа для пользователя" {
            autoLayout
            user -> web_app.user_service "Пользователь выбирает услугу"
            web_app.user_service -> web_app.user_database "Получение/Добавление информации о пользователе"
            web_app.user_service -> web_app.executor_service "Информация о необходимой услуге"
            web_app.executor_service -> web_app.executor_database "Поиск подходящих услуг"
            web_app.executor_service -> executor "Обращение в центр услуг для подтверждения заказа"
            executor -> web_app.executor_service "Ответ на запрос"
            web_app.executor_service -> web_app.executor_database "Занесение информации по услуге"
            executor -> user "Исполнение заказа"
        }

    }
}
