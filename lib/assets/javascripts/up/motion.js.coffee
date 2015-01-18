###*
Animation and transition effects.
  
@class up.motion
###
up.motion = (->
  
  util = up.util
  
  defaultOptions =
    duration: 300
    delay: 0
    easing: 'ease'

  animations = {}
  defaultAnimations = {}
  transitions = {}
  defaultTransitions = {}
  
  ###*
  Animates an element.
  
  The following animations are pre-registered:
  
  - `fade-in`
  - `fade-out`
  - `move-to-top`
  - `move-from-top`
  - `move-to-bottom`
  - `move-from-bottom`
  - `move-to-left`
  - `move-from-left`
  - `move-to-right`
  - `move-from-right`
  - `none`
  
  @method up.animate
  @param {Element|jQuery|String} elementOrSelector
  @param {String|Function|Object} animation
  @param {Number} [options.duration]
  @param {String} [options.easing]
  @param {Number} [options.delay]
  @return {Promise}
    A promise for the animation's end.
  ###
  animate = (elementOrSelector, animation, options) ->
    $element = $(elementOrSelector)
    options = util.options(options, defaultOptions)
    if util.isFunction(animation)
      assertIsPromise(
        animation($element, options),
        ["Animation did not return a Promise", animation]
      )
    else if util.isString(animation)
      animate($element, findAnimation(animation), options)
    else if util.isHash(animation)
      util.cssAnimate($element, animation, options)
    else
      util.error("Unknown animation type", animation)
      
  findAnimation = (name) ->
    animations[name] or util.error("Unknown animation", animation)

  withGhosts = ($old, $new, block) ->
    $oldGhost = null
    $newGhost = null
    util.temporaryCss $new, display: 'none', ->
      $oldGhost = util.prependGhost($old).addClass('up-destroying')
    util.temporaryCss $old, display: 'none', ->
      $newGhost = util.prependGhost($new)
    # $old should take up space in the page flow until the transition ends
    $old.css(visibility: 'hidden')
    
    newCssMemo = util.temporaryCss($new, display: 'none')
    promise = block($oldGhost, $newGhost)
    promise.then ->
      $oldGhost.remove()
      $newGhost.remove()
      # Now that the transition is over we show $new again.
      # Since we expect $old to be removed in a heartbeat,
      # $new should take up space
      $old.css(display: 'none')
      newCssMemo()
      
  assertIsPromise = (object, messageParts) ->
    util.isPromise(object) or util.error(messageParts...)
    object

  ###*
  Performs a transition between two elements.
  
  The following transitions  are pre-registered:
  
  - `cross-fade`
  - `move-top`
  - `move-bottom`
  - `move-left`
  - `move-right`
  - `none`
  
  You can also compose a transition from two animation names
  separated by a slash character (`/`):
  
  - `move-to-bottom/fade-in`
  - `move-to-left/move-from-top`
  
  @method up.morph
  @param {Element|jQuery|String} source
  @param {Element|jQuery|String} target
  @param {Function|String} transitionOrName
  @param {Number} [options.duration]
  @param {String} [options.easing]
  @param {Number} [options.delay]
  @return {Promise}
    A promise for the transition's end.
  ###  
  morph = (source, target, transitionOrName, options) ->
    options = util.options(defaultOptions)
    $old = $(source)
    $new = $(target)
    transition = util.presence(transitionOrName, util.isFunction) || transitions[transitionOrName]
    if transition
      withGhosts $old, $new, ($oldGhost, $newGhost) ->
        assertIsPromise(
          transition($oldGhost, $newGhost, options),
          ["Transition did not return a promise", transitionOrName]
        )
    else if animation = animations[transitionOrName]
      $old.hide()
      animate($new, animation, options)
    else if util.isString(transitionOrName) && transitionOrName.indexOf('/') >= 0
      parts = transitionOrName.split('/')
      transition = ($old, $new, options) ->
        $.when(
          animate($old, parts[0], options),
          animate($new, parts[1], options)
        )
      morph($old, $new, transition, options)
    else
      util.error("Unknown transition: #{transitionOrName}")

  ###*
  Defines a named transition.
  
  @method up.transition
  @param {String} name
  @param {Function} transition
  ###
  transition = (name, transition) ->
    transitions[name] = transition

  ###*
  Defines a named animation.
  
  @method up.animation
  @param {String} name
  @param {Function} animation
  ###
  animation = (name, animation) ->
    animations[name] = animation
    
  snapshot = ->
    defaultAnimations = util.copy(animations)
    defaultTransitions = util.copy(transitions)
    
  reset = ->
    animations = util.copy(defaultAnimations)
    transitions = util.copy(defaultTransitions)
  
  ###*
  Returns a no-op animation or transition which has no visual effects
  and completes instantly.
  
  @method up.motion.none
  @return {Promise}
    A resolved promise  
  ###
  none = ->
    deferred = $.Deferred()
    deferred.resolve()
    deferred.promise()
    
  animation('none', none)

  animation('fade-in', ($ghost, options) ->
    $ghost.css(opacity: 0)
    animate($ghost, { opacity: 1 }, options)
  )
  
  animation('fade-out', ($ghost, options) ->
    $ghost.css(opacity: 1)
    animate($ghost, { opacity: 0 }, options)
  )
  
  animation('move-to-top', ($ghost, options) ->
    $ghost.css('margin-top': '0%')
    animate($ghost, { 'margin-top': '-100%' }, options)
  )
  
  animation('move-from-top', ($ghost, options) ->
    $ghost.css('margin-top': '-100%')
    animate($ghost, { 'margin-top': '0%' }, options)
  )
    
  animation('move-to-bottom', ($ghost, options) ->
    $ghost.css('margin-top': '0%')
    animate($ghost, { 'margin-top': '100%' }, options)
  )
  
  animation('move-from-bottom', ($ghost, options) ->
    $ghost.css('margin-top': '100%')
    animate($ghost, { 'margin-top': '0%' }, options)
  )
  
  animation('move-to-left', ($ghost, options) ->
    $ghost.css('margin-left': '0%')
    animate($ghost, { 'margin-left': '-100%' }, options)
  )
  
  animation('move-from-left', ($ghost, options) ->
    $ghost.css('margin-left': '-100%')
    animate($ghost, { 'margin-left': '0%' }, options)
  )
  
  animation('move-to-right', ($ghost, options) ->
    $ghost.css('margin-left': '0%')
    animate($ghost, { 'margin-left': '100%' }, options)
  )
  
  animation('move-from-right', ($ghost, options) ->
    $ghost.css('margin-left': '100%')
    animate($ghost, { 'margin-left': '0%' }, options)
  )
  
  animation('roll-down', ($ghost, options) ->
    fullHeight = $ghost.height()
    styleMemo = util.temporaryCss($ghost,
      height: '0px'
      overflow: 'hidden'
    )
    animate($ghost, { height: "#{fullHeight}px" }, options).then(styleMemo)
  )
  
  transition('none', none)
  
  transition('move-left', ($old, $new, options) ->
    $.when(
      animate($old, 'move-to-left', options),
      animate($new, 'move-from-right', options)
    )
  )
  
  transition('move-right', ($old, $new, options) ->
    $.when(
      animate($old, 'move-to-right', options),
      animate($new, 'move-from-left', options)
    )
  )
  
  transition('move-up', ($old, $new, options) ->
    $.when(
      animate($old, 'move-to-top', options),
      animate($new, 'move-from-bottom', options)
    )
  )
  
  transition('move-down', ($old, $new, options) ->
    $.when(
      animate($old, 'move-to-bottom', options),
      animate($new, 'move-from-top', options)
    )
  )
  
  transition('cross-fade', ($old, $new, options) ->
    $.when(
      animate($old, 'fade-out', options),
      animate($new, 'fade-in', options)
    )
  )

  up.bus.on 'framework:ready', snapshot
  up.bus.on 'framework:reset', reset
    
  morph: morph
  animate: animate
  transition: transition
  animation: animation
  none: none

)()

up.transition = up.motion.transition
up.animation = up.motion.animation
up.morph = up.motion.morph
up.animate = up.motion.animate