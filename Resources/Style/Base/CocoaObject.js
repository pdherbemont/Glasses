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

CocoaObject.documentCocoaObject = function()
{
    return window.PlatformView.viewBackendObject(new CocoaObject);
}

/**
 * This function is used by the backend to create a new
 * CocoaObject.
 */
CocoaObject.prototype.clone = function () { return new CocoaObject; };


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

/**
 * This functions creates in the backend an NSArrayController, and store
 * it in the returned CocoaObject.
 * It is bound to the keyPath property of the called CocoaObject.
 *
 * @param {string} keyPath to observe
 * @return {CocoaObject} a CocoaObject that points to an arrayController
 */
CocoaObject.prototype.createArrayControllerFromKeyPath = function (keyPath)
{
    return window.PlatformView.createArrayControllerFromBackendObjectWithKeyPath(this, keyPath);
}
