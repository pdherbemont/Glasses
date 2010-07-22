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

CocoaObject.prototype = {
    set backendObject(n)
    {
        Lunettes.willChange(this, "backendObject");
        this._backendObject = n;
        Lunettes.didChange(this, "backendObject");
    },
    get backendObject()
    {
        if (!this._backendObject)
            this._backendObject = null;
        return this._backendObject;
    }
}
var documentCocoaObject = null;
CocoaObject.documentCocoaObject = function()
{
    if (!documentCocoaObject && window.PlatformView.documentBackendObject)
        documentCocoaObject = window.PlatformView.documentBackendObject(new CocoaObject)
    return documentCocoaObject;
}

var windowCocoaObject = null;
CocoaObject.windowCocoaObject = function()
{
    if (!windowCocoaObject && window.PlatformView.viewBackendObject)
        windowCocoaObject = window.PlatformView.viewBackendObject(new CocoaObject)
    return windowCocoaObject;
}

CocoaObject.createMediaFromURL = function(url)
{
    return window.PlatformView.createMediaFromURL(url, new CocoaObject);
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
    window.PlatformView.removeObserverForCocoaObjectWithKeyPath(observer, this, keyPath);
}

/**
 * @param {CocoaObject} object
 * @param {number} index
 */
CocoaObject.prototype.insertObjectAtIndex = function (object, index)
{
    window.PlatformView.insertObjectAtIndexInArrayController(object, index, this);
}

/**
 * @param {number} index
 */
CocoaObject.prototype.setSelectedIndexes = function (index)
{
    window.PlatformView.setSelectedIndexesInArrayController(index, this);
}

/**
 * @param {Object} value
 * @param {string} key
 */
CocoaObject.prototype.setValueForKey = function (value, key)
{
    window.PlatformView.setObjectValueForKey(this, value, key);
}

/**
 * @param {string} key
 */
CocoaObject.prototype.valueForKey = function (key)
{
    return window.PlatformView.objectValueForKey(this, key);
}



/**
 * This functions creates in the backend an NSArrayController, and store
 * it in the returned CocoaObject.
 * It is bound to the keyPath property of the called CocoaObject.
 *
 * @param {string} keyPath to observe
 * @param {string=} filterPredicate
 * @return {CocoaObject} a CocoaObject that points to an arrayController
 */
CocoaObject.prototype.createArrayControllerFromKeyPath = function (keyPath, filterPredicate)
{
    if (!filterPredicate)
        filterPredicate = null;
    return window.PlatformView.createArrayControllerFromBackendObjectWithKeyPathAndFilterPredicate(this, keyPath, filterPredicate);
}
