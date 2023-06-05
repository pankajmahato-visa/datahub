import json
from .converter import *


dummy_file=open(DUMMY_DATA_PATH,'r')
dummy_data=dummy_file.read()

data=JSONTolist(dummy_data)
