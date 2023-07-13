### Copy directory default_role_action to /tmp on datahub-actions container or any other writable path

### Export path under env variable PYTHONPATH
export PYTHONPATH=/tmp/default_role_action  

### Update variables in .yaml file 
add token if required  
change default required role  
change gms host port  
set http schema and add certificates for https   

### Execute with following command   
datahub actions -c /tmp/default_role_action/default_role.yaml  
  
### Use setup.py to install as a module (needs write access to python site-packages dir)   
pip install -e .  
