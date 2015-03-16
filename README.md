## Mabolo
Just a simple ORM of MongoDB API.

> 这个东西还是非常好的嘛！—— Master Yeechan  
> 和 Mongoose 各有千秋。—— orzFly

![Travis-CI](https://img.shields.io/travis/jysperm/Mabolo.svg?style=flat-square)
![NPM Version](https://img.shields.io/npm/v/mabolo.svg?style=flat-square)
![NPM Downloads](https://img.shields.io/npm/dm/mabolo.svg?style=flat-square)

* [Document](http://mabolo.hackplan.com)
* [NPM](https://www.npmjs.com/package/mabolo)
* MIT License

## Features

* Define Schema and validate document

  ```coffee
  User = mabolo.model 'User',
    username:
      type: String
      required: true

    password: String

    age:
      type: Number
      default: 18
  ```

* Define model methods and document methods

  ```coffee
  User.findByName = (name, options...) ->
    return @findOne name: name, options...

  User::getName = ->
    return @username
  ```

* Support embedded and reference relationship

  ```coffee
  Token = mabolo.model 'Token',
    code: String

  User = mabolo.model 'User',
    tokens: [Token]

    partner:
      type: mabolo.ref 'User'
  ```

* Promise style and callback style API

  ```coffee
  User.create
    name: 'jysperm'
  .then (jysperm) ->

  User.create
    name: 'jysperm'
  , (err, jysperm) ->
  ```

* Modify document atomically

  ```coffee
  jysperm.modify (jysperm) ->
    Q.delay(1000).then ->
      jysperm.age = 19
  .then ->
  ```
