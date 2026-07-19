from flask import Flask

app = Flask(__name__)
@app.route('/')

def python_script():
    return "Hello from the security pipeline demo"
if __name__ == '__main__':
    app.run(debug=True)
