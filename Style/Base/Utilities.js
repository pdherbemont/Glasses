/******************************************************************************
 *
 * DOM Element additional methods
 *
 */


/**
 * Has a className
 * @param {string} className
 */
Element.prototype.hasClassName = function (className)
{
    return this.className.indexOf(className) != -1;
}

/**
 * Has a className in ancestors or self
 * @param {string} className
 */
Element.prototype.hasClassNameInAncestors = function(className)
{
    if (this.hasClassName(className))
        return true;
    var parent = this.parentNode;
    if (!parent || !parent.hasClassNameInAncestors)
        return false;
    return parent.hasClassNameInAncestors(className);
}

/**
 * Remove a className
 * @param {string} className
 */
Element.prototype.removeClassName = function(className)
{
    if(!this.hasClassName(className))
        return;
    var classes = this.className.replace(className, "");
    this.className = classes.replace("  ", " ");
}

/**
 * Add a className
 * @param {string} className
 */
Element.prototype.addClassName = function (className)
{
    if(this.hasClassName(className))
        return;
    this.className += " " + className;
}


/**
 * XXX: To Remove?
 */

Element.prototype.isAttached = function ()
{
    return this.parentNode;
}

Element.prototype.detach = function ()
{
    window.console.assert(this.parentNode)
    this.parentNode.removeChild(this);
}

/**
 * Bind "property" to root object "toKeyPath"
 * @param {string} property
 * @param {string} toKeyPath
 */

Element.prototype.bindKey = function (property, toKeyPath)
{
    window.PlatformView.bindDOMObjectToCocoaObject(this, property, CocoaObject.documentCocoaObject(), toKeyPath);
}

/******************************************************************************
 *
 * Array Element additional methods
 *
 */

/**
 * Get the last element of an array
 * @param {Array} array
 */
function last(array)
{
    return array[array.length - 1];
}

Lunettes.last = last;

/******************************************************************************
 *
 * Function Element additional methods
 *
 */

/**
 * Return a function that will ensure that when called its "this" property
 * is set to "thisObject". Especially useful for passing object methods to event
 * handlers.
 * @param {Object} thisObject
 */

Function.prototype.bind = function(thisObject)
{
    var func = this;
    var args = Array.prototype.slice.call(arguments, 1);

    if (!thisObject.Binded)
        thisObject.Binded = new Object;
    if (thisObject.Binded[this])
        return thisObject.Binded[this];
    var f = function() { return func.apply(thisObject, args.concat(Array.prototype.slice.call(arguments, 0))) };
    thisObject.Binded[this] = f;
    return f;
}

/******************************************************************************
 *
 * Other additional methods
 *
 */

/**
 * @param {string} className
 * @param {Function} method
*/
function bindButtonByClassNameToMethod(className, method)
{
    bindByClassNameActionToMethod(className, 'click', method);
}

Lunettes.bindButtonByClassNameToMethod = bindButtonByClassNameToMethod;

/**
 * @param {string} className
 * @param {string} action - eg 'click', 'dblclick'.
 * @param {Function} method
 */
function bindByClassNameActionToMethod(className, action, method)
{
    var buttons = document.getElementsByClassName(className);
    for(var i = 0; i < buttons.length; i++)
        buttons.item(i).addEventListener(action, method, false);
}

Lunettes.bindByClassNameActionToMethod = bindByClassNameActionToMethod;



/**
 * Do a Cocoa Bindings between a CocoaObject and a DOMObject
 * @param {Object} domobject
 * @param {string} keyPath1
 * @param {Object} object
 * @param {string} keyPath2
 * @param {Object=} options
 */
Lunettes.connect = function (domobject, keyPath1, object, keyPath2, options)
{
    if (object.backendObject)
        window.PlatformView.bindDOMObjectToCocoaObject(domobject, keyPath1, object, keyPath2, options);
    else
        window.PlatformView.bindDOMObjectToObject(domobject, keyPath1, object, keyPath2, options);
}

/**
 * @param {Object} object
 * @param {string} key
 */
Lunettes.unconnect = function (object, key)
{
    window.PlatformView.unbindDOMObject(object, key);
}

/**
 * @param {Object} object
 * @param {string} key
 */
Lunettes.willChange = function (object, key)
{
    window.PlatformView.willChange(object, key);
}

/**
 * @param {Object} object
 * @param {string} key
 */
Lunettes.didChange = function (object, key)
{
    window.PlatformView.didChange(object, key);
}


function isEnterKey(event)
{
    return event.keyCode !== 229 && event.keyIdentifier === "Enter";
}


