import os
import requests

def handler(event, context):
  
  r = requests.get('https://www.python.org')

  return {
    'status_code': r.status_code,
    'name': os.getenv('NAME'),
    'message': 'Hello World',
  }
