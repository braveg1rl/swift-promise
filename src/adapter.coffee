SwiftPromise = require "./swift-promise"

module.exports = 
  pending: ->
    pending = {}
    pending.promise = new SwiftPromise (cb) ->
      pending.fulfill = (value) -> cb null, value
      pending.reject = (error) -> cb error, null, true
    pending
  fulfilled: SwiftPromise.return
  rejected: SwiftPromise.throw