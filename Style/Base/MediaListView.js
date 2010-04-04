/**
 * A list of MediaView
 * @constructor
 * @extends {ListView}
 * @implements {KVCArrayObserver}
 * @param {CocoaObject} cocoaObject
 * @param {string} subItemsKeyPath
 * @param {Node=} element
 */
var MediaListView = function(cocoaObject, subItemsKeyPath, element)
{
    // Calling super class
    ListView.call(this, cocoaObject, subItemsKeyPath, MediaView, element);
}

MediaListView.prototype = {
    /**
     * Show the header with name and back button
     * @type {boolean}
     */
    _showNavigationHeader: false,
    set showNavigationHeader(show)
    {
        if (this._showNavigationHeader == show)
            return;
        this._showNavigationHeader = show;
        if (show) {
            this.navigationHeaderElement = document.createElement("div");
            this.navigationHeaderElement.className = "header";

            this.nameElement = document.createElement("div");
            this.nameElement.className = "name";

            this.backButtonElement = document.createElement("button");
            this.backButtonElement.textContent = "Back";
            this.backButtonElement.className = "back";
        }
        else {
            this.navigationHeaderElement.detach();
            this.navigationHeaderElement = null;
            this.nameElement = null;
            this.backButtonElement = null;
        }
    },
    get showNavigationHeader()
    {
        return this._showNavigationHeader;
    },

    /**
     * Nav headers' back button clicked.
     * @param {Event} event
     */
    backClicked: function(event)
    {
        this.navigationController.pop();
    }
}

MediaListView.prototype.__proto__ = ListView.prototype;
