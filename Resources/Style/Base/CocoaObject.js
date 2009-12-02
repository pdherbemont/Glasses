/******************************************************************************
 *
 * KVCArrayObserver
 *
 */

/**
 * An object that can observe a cocoa array object.
 * @interface
 */
function KVCArrayObserver() {};
/**
 * @param {CocoaObject} cocoaObject to observe
 * @param {number} index
 */    
KVCArrayObserver.prototype.insertCocoaObject = function(cocoaObject, index) {};

/**
 * @param {CocoaObject} cocoaObject to observe
 */    
KVCArrayObserver.prototype.removeCocoaObjectAtIndex = function(cocoaObject) {};

/**
 * Remove all
 */
KVCArrayObserver.prototype.removeAllInsertedCocoaObjects = function() {};



/******************************************************************************
 *
 * CocoaObject
 *
 */

/**
 * An object that can observe a cocoa array object.
 * @constructor
 */
var CocoaObject = function() {};

/**
 * @param {string} keyPath
 * @param {Object} object
 * @param {string} property
 */    
CocoaObject.prototype.bindToObjectProperty = function (keyPath, object, property)
{
    window.console.assert(this.backendObject);
    window.PlatformView.bindDOMObjectToCocoaObject(object, property, this, keyPath);
}

/**
 * @param {Object} object
 * @param {string} property
 */    
CocoaObject.prototype.unbindOfObjectProperty = function (object, property)
{
    window.console.assert(this.backendObject);
    window.PlatformView.unbindDOMObject(object, property);
}


/**
 * @param {KVCArrayObserver} observer
 * @param {string} keyPath to observe
 */
CocoaObject.prototype.addObserver = function (observer, keyPath)
{
    window.console.assert(observer);
 
    window.PlatformView.addObserverForCocoaObjectWithKeyPath(observer, this, keyPath);
}

/**
 * @param {KVCArrayObserver} observer
 * @param {string} keyPath to observe
 */
CocoaObject.prototype.removeObserver = function (observer, keyPath)
{
    window.console.assert(observer);
    window.PlatformView.unobserve(observer, this, keyPath);
}