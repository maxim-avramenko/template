#!/usr/bin/env bash
set -e
APP_ENV=
PROJECT_PWD=
PROJECT_NAME=

# подтягиваем переменные
. ${PROJECT_PWD}"/.env"

# config variables
DATE=$(date +%F\ %T)
VERBOSE=false
DEBUG=false
HELP=false
SAVE_LOG=
INDEX_LIST=()
APPLICATION_LIST=()
# all services
# SERVICE_LIST=(`docker-compose -f common.yml -f "${APP_ENV}".yml config --services`)
SERVICE_LIST=()
PROCESS_LIST=()
PROVIDER_LIST=()
COMMAND=
WITH_CACHE=
DUMP_NAME=

#docker variables
INTERACTIVE="-i"
TTY="-t"
NETWORK_NAME=""

_showed_traceback=f

traceback() {
	# Hide the traceback() call.
	local -i start=$(( ${1:-0} + 1 ))
	local -i end=${#BASH_SOURCE[@]}
	local -i i=0
	local -i j=0

    if [[ ${VERBOSE} == true ]]; then
        echo "Traceback (last called is first):" 1>&2
    fi

	for ((i=${start}; i < ${end}; i++)); do
		j=$(( $i - 1 ))
		local function="${FUNCNAME[$i]}"
		local file="${BASH_SOURCE[$i]}"
		local line="${BASH_LINENO[$j]}"
		if [[ ${VERBOSE} == true ]]; then
            echo "     ${function}() in ${file}:${line}" 1>&2
        fi
	done
}

on_error() {
    local _ec="$?"
    local _cmd="${BASH_COMMAND:-unknown}"
    traceback 1
    _showed_traceback=t
    if [[ ${VERBOSE} == true ]]; then
        echo "The command ${_cmd} exited with exit code ${_ec}." 1>&2
    fi

}
trap on_error ERR


on_exit() {
    if [[ ${VERBOSE} == true ]]; then
        echo "Cleaning up before Exit ..."
    fi
    local _ec="$?"
    if [[ $_ec != 0 && "${_showed_traceback}" != t ]]; then
        traceback 1
    fi
}
trap on_exit EXIT


usage() {
    echo "usage: "${PROJECT_NAME}" -k value --key value --key=value -- command command command"
#    echo "      --log                               save all STDOUT to "${LOG_FILE}""
    echo
    echo "      install                             Команда для инсталяции проекта в окружении ${APP_ENV}"
    echo
    echo "      start                               Запуск проекта или сервиса"
    echo "                                          ${PROJECT_NAME} start"
    echo "              -s | --service              --service=name | -s name to build"
    echo "                                          ${PROJECT_NAME} --service=php start"
    echo "                                          ${PROJECT_NAME} -s php start"
    echo "      stop                                Остановка проекта или сервиса"
    echo "                                          ${PROJECT_NAME} stop"
    echo "              -s | --service              --service=name | -s name to stop"
    echo "                                          ${PROJECT_NAME} --service=node stop"
    echo "                                          ${PROJECT_NAME} -s node -s php stop"
    echo "      restart                             Перезапуск проекта или сервиса"
    echo "                                          ${PROJECT_NAME} restart"
    echo "              -s | --service              --service=name | -s name restart"
    echo "                                          ${PROJECT_NAME} --service=node restart"
    echo "                                          ${PROJECT_NAME} -s node -s php restart"
    echo
    echo "      ps                                  список состояние запущенных контейнеров"
    echo
    echo "      check                               проверка конфигурации окружения ${APP_ENV}"
    echo
    echo "      logs                                логи всех сервисов"
    echo "              -s | --service              --service=name | -s name to show logs"
    echo "                                          Список логов конкретных сервисов или сервиса"
    echo "                                          ${PROJECT_NAME} --service=node logs"
    echo "                                          ${PROJECT_NAME} -s node -s php logs"
    echo
    echo "      yarn                                Создание образа для установки и сборки react приложения"
    echo "                                          ${PROJECT_NAME} yarn (это алиас следующих двух команд)"
    echo "      yarn-build                          ${PROJECT_NAME} yarn-build"
    echo
    echo "      build                               build всех images"
    echo "              -n | --no-cache             build всех images или набора image без кэша"
    echo "              -s | --service              ${PROJECT_NAME} --service=php build"
    echo "                                          ${PROJECT_NAME} -s php -s db_living build"
    echo
    echo "      list                                список дампов в Selectel облаке"
    echo "              -s | --service              список дампов для определенной БД --service=name | -s name"
    echo
    echo "      restore                             восстановление бэкапа БД для всех сервисов"
    echo "              -s | --service              восстановление бэкапа БД для --service=name | -s name"
    echo
    echo "      backup                              создание бэкапов для всех баз"
    echo "              -s | --service              создание бэкапа для --service=service_name или -s service_name"
    echo
    echo "      migrate                             запускает миграции для всех БД"
    echo "              -s | --service              миграция БД для --service=name | -s name"
    echo
    echo "      upload                              выгрузка данных из nmarket и abc"
    echo "              -p | --provider             выгрузка данных из --provider=name | -p name"
    echo
    echo "      upload-nmarket                      выгрузка из nMarket"
    echo "      upload-abc                          выгрузка из ABC"
    echo
    echo "      execute                             выполниьт команду в сервисе"
    echo "              -s | --service              --service=name for execute command"
    echo "              -c | --command              --command=\"command to run in service container\""
    echo
    echo "      create-index                        создание всех индексов в ElasticSearch"
    echo "      remove-index                        удаление всех индексов"
    echo "      reindex                             реиндексация данных в Elastic"
    echo "      recreate-index                      удаление исоздание всех индексов в Elasic"
    echo "              -i | --index                --index=name создаст указанный индекс в Elastic"
    echo
    echo "      create-redirects                    recreate redirect configs for redirector service"
    echo "      restart-redirector                  restart redirector service with new configs"
    echo
    echo "      composer-install                    composer install --prefer-dist"
    echo
    echo "      init                                php init for yii2 application"
    echo
    echo "      update                              update all applications yii and react"
    echo "              -a | --app                  living --app=yii --app=react update или с короткими ключами"
    echo "                                          living -a yii -a react update"
    echo
    echo "      update-yii                          living update-yii"
    echo "      update-react                        living update-react"
    echo "      update-all                          living update-all (living update-yii update-react)"
    echo
    echo "      rating                              обнволение рейтингов для ЖК и застройщиков"
    echo
    echo "      upgrade                             обновление yii и react"
    echo
    echo "      full-upgrade                        full upgrade project with yarn, yarn-build and recreate-index commands"
    echo
    echo "      pull                                git pull for current project brunch"
    echo
    echo "      services                            список всех доступных сервисов"
    echo
    echo "      volumes                             список всех виртуальных дисков"
    echo
    echo "Production commands:"
    echo
    echo "      init-tc                             Установка TeamCity"
    echo "      start-tc                            Запуск TeamCity"
    echo "      stop-tc                             Остановка TeamCity"
    echo "      restart-tc                          Перезапуск TeamCity"
    echo "      ps-tc                               Статус TeamCity"
    echo
    echo "      backup                              backup всех баз данных в Selectel контейнеры"
    echo "              -s name | --service=name    backup конкретной БД из сервиса в Selectel контейнеры"
    echo
    echo "Optional arguments:"
    echo
    echo "      -v | --verbose                      run script in VERBOSE mode, print interactive script messages to STOUT"
    echo "      -d | --debug                        run script in DEBUG mode, print all script process to STDOUT"
    echo
    echo "      -h | --help                         display this help and exit"
    echo
    echo "
Usage examples:
    "${PROJECT_NAME}"
"
}

OPTS=`getopt -o vdhs:c:a:i:np: --long verbose,debug,help,service:,command:,app:,index:,no-cache,dump-name:,provider:,no-tty,no-interactive,network -- "$@"`

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

#echo "$OPTS"
eval set -- "${OPTS}"

while true; do
  case "$1" in
    -v | --verbose )
        set -v
        VERBOSE=true
        shift
    ;;
    -d | --debug )
        set -x
        DEBUG=true
        shift
    ;;
    -h | --help )
        HELP=true
        shift
    ;;
    --no-interactive )
        INTERACTIVE=
        shift
    ;;
    --no-tty )
        TTY=
        shift
    ;;
    -s | --service )
        case "$2" in
            "")
                shift 2
            ;;
            *)
                SERVICE_LIST=("${SERVICE_LIST[@]}" "$2")
                shift 2
            ;;
        esac
    ;;
    -c | --command )
        case "$2" in
            "")
                shift 2
            ;;
            *)
                COMMAND="${2}"
                shift 2
            ;;
        esac
    ;;
    -n | --no-cache )
        WITH_CACHE="--no-cache"
        shift
    ;;
    --network )
        NETWORK_NAME="${PROJECT_NAME}"
        shift
    ;;
    -a | --app )
        case "$2" in
            "")
                shift 2
            ;;
            *)
                APPLICATION_LIST=("${APPLICATION_LIST[@]}" "$2")
                shift 2
            ;;
        esac
    ;;
    -i | --index )
        case "$2" in
            "")
                shift 2
            ;;
            *)
                INDEX_LIST=("${INDEX_LIST[@]}" "$2")
                shift 2
            ;;
        esac
    ;;
    -p | --provider )
        case "$2" in
            "")
                shift 2
            ;;
            *)
                PROVIDER_LIST=("${PROVIDER_LIST[@]}" "$2")
                shift 2
            ;;
        esac
    ;;
    --dump-name )
        case "$2" in
            "")
                shift 2
            ;;
            *)
                DUMP_NAME="$2"
                shift 2
            ;;
        esac
    ;;
    -- )
        shift
        #echo "Создаем PROCESS_LIST"
        PROCESS_LIST=("$@")
        #echo "попали сюда ===================="
        #echo "PROCESS_LIST="${PROCESS_LIST[@]}""
        #echo "Закончили....."
        break
    ;;
    * )
       break
    ;;
  esac
done

# remove old db volumes, нужно быть очень осторожным при выполнении этих команд
# docker volume rm living_db_backup_data living_db_bigdata_data living_db_bigdata_backup_data living_db_cabinet_backup_data living_db_cabinet_data living_db_data living_dbservice_data living_dbtest_data

# remove docker images
# docker rmi arm-dbservice:v2.0 arm-db-cabinet:v2.0 arm-db-bigdata:v2.0 arm-dbtest:v2.0 arm-db:v2.0

# Список всех сервисов
services()
{
    cd "${PROJECT_PWD}"
    docker-compose -f common.yml -f "${APP_ENV}".yml config --services
}

# Список всех виртуальных дисков
volumes()
{
    cd "${PROJECT_PWD}"
    docker-compose -f common.yml -f "${APP_ENV}".yml config --volumes
}

# проверка конфигурации
check()
{
    cd "${PROJECT_PWD}"
    docker-compose -f common.yml -f "${APP_ENV}".yml config
}

# команда для билда всех контейнеров
build()
{
    cd "${PROJECT_PWD}"
    if [[ "${#SERVICE_LIST[@]}" > 0 ]]; then
        docker-compose -f common.yml -f "${APP_ENV}".yml build ${WITH_CACHE} ${SERVICE_LIST[@]}
    else
        docker-compose -f common.yml -f "${APP_ENV}".yml build ${WITH_CACHE}
    fi
}
# Старт приложения включая проксю
start()
{
    network
    if [[ "${#APPLICATION_LIST[@]}" > 0 ]]; then
        for app in "${APPLICATION_LIST[@]}"
        do
            case "${app}" in
            "teamcity" )
                #if [[ "${APP_ENV}" == "stage" ]]; then
                cd "${TEAMCITY_PWD}"
                docker-compose up -d
                #fi
            ;;
            "agent" )
                cd "${TEAMCITY_PWD}"
                docker-compose -f agent.yml up -d
            ;;
            "scope" )
                cd "${PROJECT_PWD}"
                docker-compose -f scope.yml up -d
            ;;
            "portainer" )
                cd "${PROJECT_PWD}"
                docker-compose -f portainer.yml up -d
            ;;
            "elastic" )
                cd "${PROJECT_PWD}"
                if [[ "${APP_ENV}" == "dev" ]]; then
                    docker-compose -f elastic-dev.yml up -d
                else
                    docker-compose -f elastic.yml up -d
                fi
            ;;
            esac
        done
    fi

    if [[ "${#SERVICE_LIST[@]}" > 0 ]]; then
        cd "${PROJECT_PWD}"
        docker-compose -f common.yml -f "${APP_ENV}".yml start ${SERVICE_LIST[@]}
    fi

    if [ "${#SERVICE_LIST[@]}" == 0 ] && [ "${#APPLICATION_LIST[@]}" == 0 ]; then
        cd "${PROJECT_PWD}"
        if [[ "${APP_ENV}" == "dev" ]]; then
            docker-compose -f elastic-dev.yml up -d
        else
            docker-compose -f elastic.yml up -d
        fi
        docker-compose -f common.yml -f "${APP_ENV}".yml up -d
    fi
}

# Остановка приложений и сервисов, сеть не трогаем
stop()
{
    if [[ "${#APPLICATION_LIST[@]}" > 0 ]]; then
        for app in "${APPLICATION_LIST[@]}"
        do
            case "${app}" in
            "teamcity" )
                #if [[ "${APP_ENV}" == "stage" ]]; then
                    cd "${TEAMCITY_PWD}"
                    docker-compose down
                #fi
            ;;
            "agent" )
                cd "${TEAMCITY_PWD}"
                docker-compose -f agent.yml down
            ;;
            "scope" )
                cd "${PROJECT_PWD}"
                docker-compose -f scope.yml down
            ;;
            "portainer" )
                cd "${PROJECT_PWD}"
                docker-compose -f portainer.yml down
            ;;
            "elastic" )
                cd "${PROJECT_PWD}"
                if [[ "${APP_ENV}" == "dev" ]]; then
                    docker-compose -f elastic-dev.yml down
                else
                    docker-compose -f elastic.yml down
                fi
            ;;
            esac
        done
    fi

    if [[ "${#SERVICE_LIST[@]}" > 0 ]]; then
        cd "${PROJECT_PWD}"
        #docker-compose -f common.yml -f "${APP_ENV}".yml stop ${SERVICE_LIST[@]}
        yes | docker-compose -f common.yml -f "${APP_ENV}".yml rm --stop --force ${SERVICE_LIST[@]}
    fi

    if [ "${#SERVICE_LIST[@]}" == 0 ] && [ "${#APPLICATION_LIST[@]}" == 0 ]; then
        cd "${PROJECT_PWD}"
        docker-compose -f common.yml -f "${APP_ENV}".yml down
    fi

    if [[ "${NETWORK_NAME}" == "${PROJECT_NAME}" ]]; then
        docker network rm "${NETWORK_NAME}"
    fi
}
# рестарт приложения это остановка и включение
restart(){
    if [[ "${#APPLICATION_LIST[@]}" > 0 ]]; then
        for app in "${APPLICATION_LIST[@]}"
        do
            case "${app}" in
            "teamcity" )
                cd "${TEAMCITY_PWD}"
                docker-compose down
                docker-compose up -d
            ;;
            "agent" )
                cd "${TEAMCITY_PWD}"
                docker-compose -f agent.yml down
                docker-compose -f agent.yml up -d
            ;;
            esac
        done
    fi

    if [[ "${#SERVICE_LIST[@]}" > 0 ]]; then
        cd "${PROJECT_PWD}"
        for s in "${SERVICE_LIST[@]}"
        do
            #docker-compose -f common.yml -f "${APP_ENV}".yml stop "${s}"
            yes | docker-compose -f common.yml -f "${APP_ENV}".yml rm --stop --force "${s}"
            docker-compose -f common.yml -f "${APP_ENV}".yml create "${s}"
            docker-compose -f common.yml -f "${APP_ENV}".yml start "${s}"
        done
    fi

    if [ "${#SERVICE_LIST[@]}" == 0 ] && [ "${#APPLICATION_LIST[@]}" == 0 ]; then
        stop
        start
    fi
}

# проверка статуса запущенных контейнеров
ps()
{
    if [[ "${#APPLICATION_LIST[@]}" > 0 ]]; then
        for app in "${APPLICATION_LIST[@]}"
        do
            case "${app}" in
            "teamcity" )
                if [[ "${APP_ENV}" == "stage" ]]; then
                    cd "${TEAMCITY_PWD}"
                    docker-compose ps
                fi
            ;;
            "agent" )
                cd "${TEAMCITY_PWD}"
                docker-compose -f agent.yml ps
            ;;
            "scope" )
                cd "${PROJECT_PWD}"
                docker-compose -f scope.yml ps
            ;;
            "portainer" )
                cd "${PROJECT_PWD}"
                docker-compose -f portainer.yml ps
            ;;
            "elastic" )
                cd "${PROJECT_PWD}"
                if [[ "${APP_ENV}" == "dev" ]]; then
                    docker-compose -f elastic-dev.yml ps
                else
                    docker-compose -f elastic.yml ps
                fi
            ;;
            "all" )
                cd "${TEAMCITY_PWD}"
                docker-compose -f agent.yml ps
                docker-compose ps
                cd "${PROJECT_PWD}"
                docker-compose -f scope.yml ps
                docker-compose -f portainer.yml ps
                docker-compose -f common.yml -f "${APP_ENV}".yml ps
                if [[ "${APP_ENV}" == "dev" ]]; then
                    docker-compose -f elastic-dev.yml ps
                else
                    docker-compose -f elastic.yml ps
                fi
            ;;
            esac
        done
    else
        cd "${PROJECT_PWD}"
        docker-compose -f common.yml -f "${APP_ENV}".yml ps
    fi
}

# Просмотр логов всех контейнеров
logs(){
    cd "${PROJECT_PWD}"
    if [[ "${#SERVICE_LIST[@]}" > 0 ]]; then
        for i in "${SERVICE_LIST[@]}"
        do
            docker-compose -f common.yml -f "${APP_ENV}".yml logs "${i}"
        done
    else
        docker-compose -f common.yml -f "${APP_ENV}".yml logs
    fi

}

# команда для восстановления БД из Selectel
restore()
{
    cd "${PROJECT_PWD}"
    if [[ "${#SERVICE_LIST[@]}" > 0 ]]; then
        for i in "${SERVICE_LIST[@]}"
        do
            docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${i}"_"${APP_ENV}" /utils/restore.sh "${DUMP_NAME}"
        done
    else
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_db_living /utils/restore.sh
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_db_bigdata /utils/restore.sh
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_db_cabinet /utils/restore.sh
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_db_test /utils/restore.sh
    fi
}

# команда для backup БД
backup()
{
    cd "${PROJECT_PWD}"
    if [[ "${#SERVICE_LIST[@]}" > 0 ]]; then
        for i in "${SERVICE_LIST[@]}"
        do
            docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_"${i}" /utils/backup.sh
        done
    else
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_db_living /utils/backup.sh
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_db_bigdata /utils/backup.sh
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_db_cabinet /utils/backup.sh
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_db_test /utils/backup.sh
    fi
}

# команда для получения списка бэкапов в Selectel
list()
{
    cd "${PROJECT_PWD}"
    if [[ "${#SERVICE_LIST[@]}" > 0 ]]; then
        for i in "${SERVICE_LIST[@]}"
        do
            docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_"${i}" /utils/list.sh
        done
    fi
}

# Команда создания yarn для сборки react приложения

yarn()
{
    cd "${PROJECT_PWD}"
    docker run "${INTERACTIVE}" "${TTY}" --rm --name "${PROJECT_NAME}"_"${APP_ENV}"_yarn --workdir "/home/node/app" -v "${PROJECT_PWD}/app/react:/home/node/app" node:8.11.0 yarn install --no-progress --frozen-lockfile
}

yarn-build(){
    cd "${PROJECT_PWD}"
    docker run "${INTERACTIVE}" "${TTY}" --rm --name "${PROJECT_NAME}"_"${APP_ENV}"_yarn --workdir "/home/node/app" -v "${PROJECT_PWD}/app/react:/home/node/app" node:8.11.0 yarn run build ${YARN_BULD_KEY}
}

create-index()
{
    if [[ "${#INDEX_LIST[@]}" > 0 ]]; then
        for i in "${INDEX_LIST[@]}"
        do
            docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/create-index "${i}"
        done
    else
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/create-index living-developer
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/create-index living-complex
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/create-index living-stage
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/create-index living-building
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/create-index living-content
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/create-index living-apartment
    fi
}

remove-index()
{
    if [[ "${#INDEX_LIST[@]}" > 0 ]]; then
        for i in "${INDEX_LIST[@]}"
        do
            docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/remove-index "${i}"
        done
    else
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/remove-index living-developer
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/remove-index living-complex
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/remove-index living-stage
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/remove-index living-building
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/remove-index living-content
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/remove-index living-apartment
    fi
}

reindex(){
    if [[ "${#INDEX_LIST[@]}" > 0 ]]; then
        for i in "${INDEX_LIST[@]}"
        do
            docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/reindex "${i}"
        done
    else
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/reindex living-developer
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/reindex living-complex
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/reindex living-stage
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/reindex living-building
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/reindex living-content
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii search/reindex living-apartment
    fi
}

recreate-index()
{
    remove-index && create-index && reindex
}

create-redirects()
{
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii create-redirect-files
}

restart-redirector()
{
    CHECK=`docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_redirector nginx -t | grep successful`
    if [[ "${CHECK}" = *'successful'* ]]; then
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_redirector nginx -s reload
    else
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_redirector nginx -t
    fi
}

upload-nmarket()
{
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii upload/nmarket 78
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii upload/nmarket 77
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii upload/nmarket 23
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii upload/nmarket 66
}

upload-abc()
{
    mkdir -p "${PROJECT_PWD}"/app/arm/xml/apartment
    wget https://plan.living.ru/SiteData.xml -O "${PROJECT_PWD}"/app/arm/xml/apartment/SiteData.xml
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii upload/abc xml/apartment/SiteData.xml
}

upload()
{
    if [[ "${#PROVIDER_LIST[@]}" > 0 ]]; then
        for i in "${PROVIDER_LIST[@]}"
        do
            case "${i}" in
            nmarket )
                upload-nmarket
            ;;
            abc )
                upload-abc
            ;;
            esac
        done
    else
        upload-nmarket
        upload-abc
    fi
}

execute()
{
    if [[ "${#SERVICE_LIST[@]}" > 0 ]];
    then
        for i in "${SERVICE_LIST[@]}"
        do
            docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_"${i}" ${COMMAND}
        done
    fi
}

update()
{
    cd "${PROJECT_PWD}"
    if [[ "${#APPLICATION_LIST[@]}" > 0 ]]; then
        for i in "${APPLICATION_LIST[@]}"
        do
            case "${i}" in
            yii )
                update-yii
            ;;
            react )
                update-react
            ;;
            esac
        done
    else
        update-all
    fi
}

update-all()
{
    update-yii
    update-react
}

update-react()
{
    create-robots-txt
    create-sitemap
    yarn-build
    cd "${PROJECT_PWD}"
    docker-compose -f common.yml -f "${APP_ENV}".yml build --no-cache node
    #docker-compose -f common.yml -f "${APP_ENV}".yml stop node
    yes | docker-compose -f common.yml -f "${APP_ENV}".yml rm --stop --force node
    docker-compose -f common.yml -f "${APP_ENV}".yml up -d
}

update-yii()
{
    composer-install
    init
    migrate
    create-redirects
}

composer-install(){
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php composer install --prefer-dist --no-progress
}

init(){
    if [ "${APP_ENV}" == "prod" ];
    then
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php init --env=Production --overwrite=y
    else
        docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php init --env=Development --overwrite=y
    fi
}

migrate(){
    # TODO Исправить миграцию на отдельные сервисы БД, пока что одна db_living
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii migrate --interactive=0
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii db-maintenance/recreate-utils
}

# Рассчет рейтингов ЖК и Застройщиков
rating()
{
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii generate-rating/complex
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii generate-rating/developer
}

create-sitemap()
{
    docker exec "${INTERACTIVE}" "${TTY}" "${PROJECT_NAME}"_"${APP_ENV}"_php php yii sitemap/generate
    # копируем sitemaps в корень react приложения для обновления
    cp "${PROJECT_PWD}"/app/arm/xml/sitemap/* "${PROJECT_PWD}"/app/react/public
}

create-robots-txt()
{
    echo -e "\nUser-agent: *" > ""${PROJECT_PWD}"/app/react/public/robots.txt"
    if [ "${APP_ENV}" != "prod" ];
    then
        echo "Disallow: /" >> ""${PROJECT_PWD}"/app/react/public/robots.txt"
    else
        echo -e "Disallow: /*?*\nAllow: /\nHost: https://"${DOMAIN}"\nsitemap: https://"${DOMAIN}"/sitemap_index.xml\n" >> ""${PROJECT_PWD}"/app/react/public/robots.txt"
    fi
}

# функция для инициализации проекта
install()
{
    yarn
    yarn-build
    init-xhgui
    check
    build
    composer-install-xhgui
    start
    composer-install
    init
    restore
    migrate
    create-redirects
    update-react
    recreate-index
}

# Обновление проекта для разработчика, нужно выполнять как можно чаще в той ветке в которой работаеш
upgrade()
{
    start
    yarn
    if [ "${APP_ENV}" == "prod" ]; then
        backup
    else
        restore
    fi
    update-all
    if [ "${APP_ENV}" == "prod" ]; then
        upload
        rating
        backup
    fi
}

full-upgrade()
{
    upgrade
    recreate-index
}

pull()
{
    cd "${PROJECT_PWD}"
    git pull
}

# инициализация xhgui
init-xhgui()
{
    if [ ! -d "${PROJECT_PWD}/app/xhgui" ]; then
        git clone https://github.com/perftools/xhgui.git
        chmod 0777 xhgui/cache
        cp "${PROJECT_PWD}"/docker/source/xhgui/config/config.default.php "${PROJECT_PWD}"/app/xhgui/config/
    fi
}
# установка зависимостей xhgui из composer
composer-install-xhgui()
{
    cd "${PROJECT_PWD}"
    docker run "${INTERACTIVE}" "${TTY}" --rm --name xhgui-composer -v "${PROJECT_PWD}"/app/xhgui:/xhgui "${PROJECT_NAME}-${APP_ENV}-php:v2.0" bash -c 'cd /xhgui && composer install --prefer-dist'
}

# Определяем включена ли сеть для сервисов
# Network ID нужен для того что бы проверить доступ к сети, все сервисы работают внутри одной сети
network()
{
    NETWORK_ID=`docker network ls --filter name="${PROJECT_NAME}" -q`
    if [[ "${#NETWORK_ID}" == 0 ]]; then
        # Если сеть отсутствует для проекта то создаем её, сеть должна быть поднята всегда
        DOCKER_COMPOSE_VERSION=`docker-compose version --short`
        docker network create "${PROJECT_NAME}" \
            -d bridge \
            --scope local \
            --attachable \
            --label com.docker.compose.network="${PROJECT_NAME}" \
            --label com.docker.compose.project="${PROJECT_NAME}" \
            --label com.docker.compose.version="${DOCKER_COMPOSE_VERSION}"

        # Пример для запуска сети вручную для проекта living
        # docker network create living \
        #   -d bridge \
        #   --scope local \
        #   --attachable \
        #   --label com.docker.compose.network=living \
        #   --label com.docker.compose.project=living \
        #   --label com.docker.compose.version=1.21.2
        #
        # docker inspect -f '{{ .HostConfig.Ulimits }}' container_name
    fi
}

# запускаем команды поочереди, в том порядке в котором запросил пользователь
if [[ "${#PROCESS_LIST[@]}" > 0 ]]; then
    #echo "Команды запускаются по порядку как указано в команде запуска!"
    for i in "${PROCESS_LIST[@]}"
    do
        #echo "Выполняем команду: ${i}"
        "${i}"
    done
else
    usage
    exit 0
fi

exit