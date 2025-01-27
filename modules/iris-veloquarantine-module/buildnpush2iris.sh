#!/bin/bash

# Help
Help()
{
   # Display Help
   echo "This script builds the DFIR-IRIS module of the current directory and installs it to DFIR-IRIS. If you run it for the first time or change something in the module configuration template make sure to run the -a switch."
   echo
   echo "Syntax: ./buildnpush2iris [-a|h]"
   echo "options:"
   echo "a     Also install the module to the iris-web_app_1 container. Only required on initial install or when changes to config template were made."
   echo "h     Print this Help."
   echo
}

Run()
{
    echo "[BUILDnPUSH2IRIS] Starting the build and push process.."
    SEARCH_DIR='./dist'
    get_recent_file () {
        FILE=$(ls -Art1 ${SEARCH_DIR} | tail -n 1)
        if [ ! -f ${FILE} ]; then
            SEARCH_DIR="${SEARCH_DIR}/${FILE}"
            get_recent_file
        fi
        echo $FILE
        exit
    }

    python3 setup.py bdist_wheel

    latest=$(get_recent_file)
    module=${latest#"./dist/"}

    echo "[BUILDnPUSH2IRIS] Found latest module file: $latest"
    echo "[BUILDnPUSH2IRIS] Copy module file to worker container.."
    sudo docker cp $latest iriswebapp_worker:/iriswebapp/dependencies/$module
    sudo docker exec -it iriswebapp_app /bin/sh -c "chown root:root dependencies/$module"
    echo "[BUILDnPUSH2IRIS] Installing module in worker container.."
    sudo docker exec -it iriswebapp_worker /bin/sh -c "pip3 install dependencies/$module --force-reinstall"

    echo "[BUILDnPUSH2IRIS] Copy module file to app container.."
    sudo docker cp $latest iriswebapp_app:/iriswebapp/dependencies/$module
    sudo docker exec -it iriswebapp_app /bin/sh -c "chown root:root dependencies/$module"
    echo "[BUILDnPUSH2IRIS] Installing module in app container.."
    sudo docker exec -it iriswebapp_app /bin/sh -c "pip3 install dependencies/$module --force-reinstall"
    
    echo "[BUILDnPUSH2IRIS] Restarting worker and app container.."
    sudo docker restart iriswebapp_worker
    sudo docker restart iriswebapp_app

    echo "[BUILDnPUSH2IRIS] Completed!"

}

while getopts ":ha" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      a) # Enter a name
         echo "[BUILDnPUSH2IRIS] Pushing to Worker and App container!"
         Run
         exit;;
     \?) # Invalid option
         echo "ERROR: Invalid option"
         exit;;

   esac
done

echo "[BUILDnPUSH2IRIS] Pushing to Worker container only!"
Run
exit
