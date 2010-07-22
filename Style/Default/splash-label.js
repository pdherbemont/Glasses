Lunettes.startEditing = function(element, committedCallback, cancelledCallback, context, multiline)
{
    console.log("mutliline" + multiline);
    if (element.__editing)
        return;
    element.__editing = true;

    var oldText = getContent(element);
    var moveDirection = "";

    element.addClassName("editing");

    var oldTabIndex = element.tabIndex;
    if (element.tabIndex < 0)
        element.tabIndex = 0;

    function blurEventListener() {
        editingCommitted.call(element);
    }

    function getContent(element) {
        if (element.tagName === "INPUT" && element.type === "text")
            return element.value;
        else
            return element.textContent;
    }

    function cleanUpAfterEditing() {
        delete this.__editing;

        this.removeClassName("editing");
        this.tabIndex = oldTabIndex;
        this.scrollTop = 0;
        this.scrollLeft = 0;

        element.removeEventListener("blur", blurEventListener, false);
        element.removeEventListener("keydown", keyDownEventListener, true);

        if (element === Lunettes.currentFocusElement /* || element.isAncestor(Lunettes.currentFocusElement) */)
            Lunettes.currentFocusElement = Lunettes.previousFocusElement;
    }

    function editingCancelled() {
        if (this.tagName === "INPUT" && this.type === "text")
            this.value = oldText;
        else
            this.textContent = oldText;

        cleanUpAfterEditing.call(this);

        if (cancelledCallback)
            cancelledCallback(this, context);
    }

    function editingCommitted() {
        cleanUpAfterEditing.call(this);

        if (committedCallback)
            committedCallback(this, getContent(this), oldText, context, moveDirection);
    }

    function keyDownEventListener(event) {
        var isMetaOrCtrl =
        event.metaKey && !event.shiftKey && !event.ctrlKey && !event.altKey;
        if (isEnterKey(event) && (!multiline || isMetaOrCtrl)) {
            editingCommitted.call(element);
            event.preventDefault();
            event.stopPropagation();
        } else if (event.keyCode === Lunettes.EventKey.Escape) {
            editingCancelled.call(element);
            event.preventDefault();
            event.stopPropagation();
        } else if (event.keyIdentifier === "U+0009") // Tab key
            moveDirection = (event.shiftKey ? "backward" : "forward");
    }

    element.addEventListener('blur', blurEventListener, false);
    element.addEventListener('keydown', keyDownEventListener, true);

    Lunettes.currentFocusElement = element;
}

/**
 * A view for a MediaDB inside a Label
 * @constructor
 * @extends MediaDBView
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var LabelMediaDBView = function(cocoaObject, parent, elementTag)
{
    MediaDBView.call(this, cocoaObject, parent, elementTag);
}

LabelMediaDBView.prototype = {
    action: function()
    {
        window.PlatformView.playArrayControllerListWithMedia(this.parent.arrayController, this.cocoaObject)
    },

    /**
     * When double clicked
     */
    removeButtonClicked: function(event)
    {
        window.PlatformView.removeLabelForMedia(this.parent.cocoaObject, this.cocoaObject);
    }
}
LabelMediaDBView.prototype.__proto__ = MediaDBView.prototype;

/**
 * A list of LabelView
 * @constructor
 * @extends ListView
 * @param {CocoaObject} cocoaObject
 * @param {string} subItemsKeyPath
 * @param {Element} elementTag
 */
var LabelListView = function(cocoaObject, subItemsKeyPath, elementTag)
{
    ListView.call(this, cocoaObject, subItemsKeyPath, LabelView, elementTag);
    this.element.addClassName("label-list-view");

    this.displayName = "LabelListView";
    this._shouldSyncSelectionWithArrayController = false;
    this._shouldAutoSelectInsertedItem = false;
}

LabelListView.prototype = {
    unselectAllBeforeSelection: function()
    {
        ListView.prototype.unselectAllBeforeSelection.call(this);
        window.unselectAll();
    },
    unselectAll: function()
    {
        // Prevent unselectingAll
    },
    select: function(item)
    {
        ListView.prototype.select.call(this, item);
        if (!item)
            return;
        var list = new ListView(item.cocoaObject, "files", LabelMediaDBView);
        window.setDetailList(item.element, list);
    }
}
LabelListView.prototype.__proto__ = ListView.prototype;

/**
 * A view for a Label
 * @constructor
 * @extends ListItemView
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var LabelView = function(cocoaObject, parent, elementTag)
{
    ListItemView.call(this, cocoaObject, parent, elementTag);
    this.element.addClassName("label-view");
}

LabelView.prototype = {
    createSubElements: function()
    {
        this.nameElement = document.createElement("div");
        this.nameElement.className = "name";
        this.nameElement.tabIndex = -1;

        this.imageElement = document.createElement("img");
        this.imageElement.src = "shelf.png";
    },
    appendSubElementsToNode: function(element)
    {
        element.appendChild(this.imageElement);
        element.appendChild(this.nameElement);
    },
    set visible(visible)
    {
        if (this._visible == visible)
            return;

        ListItemView.prototype.__lookupSetter__("visible").call(this, visible);

        if (visible) {
            this.nameElement.addEventListener('dragenter', this.dragEntered.bind(this), false);
            this.nameElement.addEventListener('dragover', this.dragOvered.bind(this), false);
            this.nameElement.addEventListener('dragleave', this.dragLeft.bind(this), false);
            this.nameElement.addEventListener('drop', this.dropped.bind(this), false);
            this.nameElement.addEventListener('dblclick', this.startEditing.bind(this), false);
            Lunettes.connect(this, "nameValue", this.cocoaObject, "name");
        } else {
            Lunettes.unconnect(this, "nameValue");
        }
    },
    drag: 0,
    dragEntered: function(evt) {
        evt.dataTransfer.dropEffect = "link";
        this.drag++;
        this.element.addClassName("drag-entered");
        evt.preventDefault();
        return true;
    },
    dragOvered: function(evt) {
        evt.dataTransfer.dropEffect = "link";
        evt.preventDefault();
        return true;
    },
    dragLeft: function(evt) {
        this.drag--;
        if (this.drag <= 0)
            this.element.removeClassName("drag-entered");
    },
    dropped: function(evt) {
        this.drag--;
        var items = window.dragData;
        this.element.removeClassName("drag-entered");
        for (var i = 0; i < items.length; i++)
            window.PlatformView.setLabelForMedia(this.cocoaObject, items[i]);
    },

    set nameValue(newVal)
    {
        if (this._nameValue == newVal)
            return;

        Lunettes.willChange(this, "nameValue");
        this.nameElement.textContent = newVal;
        this._nameValue = newVal;
        Lunettes.didChange(this, "nameValue");
    },

    get nameValue()
    {
        return this._nameValue;
    },

    committedNameChange: function(arg, newText, oldText)
    {
        this.nameValue = newText;
    },

    startEditing: function()
    {
        function nothing() {};
        Lunettes.startEditing(this.nameElement, this.committedNameChange.bind(this), nothing, null, false);
    }
}
LabelView.prototype.__proto__ = ListItemView.prototype;
