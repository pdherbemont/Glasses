/**
 * A view for a Media
 * @constructor
 * @extends ListItemView
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var MediaView = function(cocoaObject, parent, elementTag)
{
    ListItemView.call(this, cocoaObject, parent, elementTag);
    this.element.addClassName("media-view");

    this._subitemsCount = 0;

    this.displayName = "MediaView";
}


MediaView.prototype = {

    _length: null,
    set length(length)
    {
        if (!length)
            length = null;
        this._length = length;
        if (length == "00:00") {
            this.lengthElement.innerText = "--:--";
            return;
        }
        this.lengthElement.innerText = length;
    },
    get length()
    {
        return this._length;
    },

    createSubElements: function()
    {
        this.itemStatusElement = document.createElement("div");
        this.itemStatusElement.className = "item-status";

        this.nameElement = document.createElement("div");
        this.nameElement.className = "name";
        this.nameElement.textContent = "Undefined";

        this.lengthElement = document.createElement("div");
        this.lengthElement.className = "item-length";
        this.lengthElement.textContent = "--:--";

        this.imgElement = document.createElement("img");
        this.imgElement.className = "thumbnail";

        this.revealSubitemsElement = document.createElement("div");
        this.revealSubitemsElement.className = "reveal-subitems hidden";
        this.revealSubitemsElement.textContent = ">";
    },
    appendSubElementsToNode: function(element)
    {
        element.appendChild(this.itemStatusElement);
        element.appendChild(this.imgElement);
        element.appendChild(this.nameElement);
        element.appendChild(this.lengthElement);
        element.appendChild(this.revealSubitemsElement);
    },
    set visible(visible)
    {
        if (this._visible == visible)
            return;

        ListItemView.prototype.__lookupSetter__("visible").call(this, visible);

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
     * When double clicked
     */
    action: function()
    {
        if (this.subitemsCount > 0) {
            var listView = new MediaListView(this.cocoaObject, "subitems.media");
            listView.showNavigationHeader = true;
            window.windowController.navigationController.push(listView);
        }
        else
            window.PlatformView.playCocoaObject(this.cocoaObject);
    }

}

MediaView.prototype.__proto__ = ListItemView.prototype;

