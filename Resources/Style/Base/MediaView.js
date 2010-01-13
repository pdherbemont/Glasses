/**
 * A list of MediaView
 * @constructor
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var MediaView = function(cocoaObject, parent, elementTag)
{
    this.parent = parent;

    this.element = document.createElement(elementTag);
    this.element.className = "item";

    this.cocoaObject = cocoaObject;

    this.nameElement = document.createElement("div");
    this.nameElement.className = "name";
    this.nameElement.textContent = "Undefined";

    this.imgElement = document.createElement("img");
    this.imgElement.className = "thumbnail";

    this.revealSubitemsElement = document.createElement("div");
    this.revealSubitemsElement.className = "reveal-subitems hidden";
    this.revealSubitemsElement.textContent = ">";

    this.isAttached = false;

    this._subitemsCount = 0;
    this.subitemsCount = 0;

    this.displayName = "MediaView";
}


MediaView.prototype = {
    /**
     * @param {Node=} parentElement
     */
    attach: function(parentElement)
    {
        console.assert(!this.isAttached, "shouldn't be attached");

        this.element.appendChild(this.imgElement);
        this.element.appendChild(this.nameElement);
        this.element.appendChild(this.revealSubitemsElement);

        parentElement.appendChild(this.element);

        this.element.addEventListener('mousedown', this.mouseDown.bind(this), false);
        this.element.addEventListener('dblclick', this.mouseDoubleClicked.bind(this), false);

        this.isAttached = true;
    },
    detachWithoutRemoving: function()
    {
        this.visible = false;
        this.isAttached = false;
    },
    detach: function()
    {
        this.element.detach();
    },

    _visible: false,
    get visible()
    {
        return this._visible;
    },
    set visible(visible)
    {
        console.assert(this.isAttached);

        if (this._visible == visible)
            return;
        this._visible = visible;
        if (visible) {
            Lunettes.connect(this.nameElement, "textContent", this.cocoaObject, "metaDictionary.title");
            var options = new Object;
            options["NSNullPlaceholderBindingOption"] = "noartwork.png";
            Lunettes.connect(this.imgElement, "src", this.cocoaObject, "metaDictionary.artworkURL", options);
            Lunettes.connect(this, "state", this.cocoaObject, "state");
            Lunettes.connect(this, "subitemsCount", this.cocoaObject, "subitems.media.@count");

        } else {
            Lunettes.unconnect(this.nameElement, "textContent");
            Lunettes.unconnect(this.imgElement, "src");
            Lunettes.unconnect(this, "state");
            Lunettes.unconnect(this, "subitemsCount");
        }
    },

    /**
     * @type {number}
     */
    _state: 0,
    set state(state){

        // Make sure if count is undef (which might be the case, especially
        // if one in the object of the binding is nil.
        // Default it to 0 instead of undefined.
        if (!state)
            state = 0;
        this._state = state;
        if (this._state)
            this.element.addClassName("item-playing");
        else
            this.element.removeClassName("item-playing");
    },
    get state(){
        return this._state;
    },

    /**
     * @type {number}
     */
    _subitemsCount: 0,
    set subitemsCount(count){

        // Make sure if count is undef (which might be the case, especially
        // if one in the object of the binding is nil.
        // Default it to 0 instead of undefined.
        if (!count)
            count = 0;

        if (count > 0)
            this.revealSubitemsElement.removeClassName("hidden");
        else
            this.revealSubitemsElement.addClassName("hidden");
        this._subitemsCount = count;
        return 0;
    },
    get subitemsCount(){
        return this._subitemsCount;
    },

    /**
     * Event Handler
     * @param {Event} event
     */
    mouseDown: function(event)
    {
        if (!this.parent)
            return;

        this.parent.select(this);
        event.stopPropagation();
    },

    /**
     * Event Handler
     * @param {Event} event
     */
    mouseDoubleClicked: function(event)
    {
        this.action();
        event.stopPropagation();
    },

    /**
     * When double clicked
     */
    action: function()
    {
        if (this.subitemsCount > 0) {
            var listView = new MediaListView(this.cocoaObject);
            listView.showNavigationHeader = true;
            window.windowController.navigationController.push(listView);
        }
        else
            window.PlatformView.playCocoaObject(this.cocoaObject);
    }

}
