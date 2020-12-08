from flask import Flask
import os
import socket

app = Flask(__name__)

@app.route("/")
def hello():
  html = "<h3>Hello World!</h3>\n"
  return html.format()

if __name__ == "__main__":
  app.run(host='0.0.0.0', port=32080)