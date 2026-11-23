from flask import Flask, request

app = Flask(__name__)


@app.route('/hello')
def hello():
    name = request.args.get('name')
    return f"Hello, {name}!"      # CWE-79: XSS reflejado


if __name__ == '__main__':
    app.run(debug=True)           # CWE-489: depurador expuesto
