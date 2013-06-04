require "setimmediate"

PENDING = 0
WAITING = 1
FULFILLED = 2
REJECTED = 3

module.exports = class SwiftPromise
  constructor: (fn) ->
    @state = 0
    @value = undefined
    @callbacks = []
    @dependents = []
    return unless fn
    resultCB = (err, result, forceError = false) =>
      if err or forceError then @settleOn REJECTED, err else @resolve result
    try fn resultCB catch error then resultCB error, null, true

  then: (onFulfilled, onRejected) ->
    dependent = 
      promise: new SwiftPromise
      cb: if typeof onFulfilled is "function" then onFulfilled else null
      eb: if typeof onRejected is "function" then onRejected else null
    if @state > 1 then setImmediate => @callDependent dependent else @dependents.push dependent
    dependent.promise
  
  settleOn: (state, value) ->
    return if @state > 1
    @state = state
    @value = value
    callback() while callback = @callbacks.shift()
    @callDependent dependent while dependent = @dependents.shift()
    
  callDependent: (d) ->
    fn = if @state is FULFILLED then d.cb else d.eb
    unless fn
      switch @state
        when FULFILLED then d.promise.resolve @value 
        when REJECTED then d.promise.settleOn REJECTED, @value
    try d.promise.resolve fn @value catch e then d.promise.settleOn REJECTED, e
  
  fulfill: (x) ->
    @resolve x unless @state

  reject: (reason) -> 
    @settleOn REJECTED, reason unless @state

  resolve: (x) ->
    return if @state > 1
    @state = WAITING
    if x instanceof SwiftPromise
      return @settleOn REJECTED, new TypeError "You may not fulfill a promise with itself." if x is @
      return @settleOn x.state, x.value if x.state > 1
      return x.callbacks.push => @settleOn x.state, x.value
    return @settleOn FULFILLED, x if not x
    return @settleOn FULFILLED, x unless typeof x in ["object","function"]
    try xThen = x.then catch err then return @settleOn REJECTED, err
    @settleOn FULFILLED, x unless typeof xThen is "function"
    resolver = makeResolver @, x
    try xThen.call x, resolver.fulfill, resolver.reject
    catch err then resolver.reject err

makeResolver = (promise, x) ->
  resolved = false
  fulfill: (value) ->
    return if resolved
    resolved = true
    if value is x then  promise.settleOn FULFILLED, value else promise.resolve value
  reject: (reason) ->
    return if resolved
    resolved = true
    promise.settleOn REJECTED, reason

SwiftPromise.return = (val) -> new FulfilledPromise val
SwiftPromise.throw = (val) -> new RejectedPromise val

class FulfilledPromise extends SwiftPromise
  constructor: (val) ->
    @state = 0
    @value = undefined
    @callbacks = []
    @dependents = []
    @resolve val

class RejectedPromise extends SwiftPromise
  constructor: (val) ->
    @state = REJECTED
    @value = val
    @dependents = []
    @callbacks = []