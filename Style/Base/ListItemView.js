/**
 * A view for a Media
 * @constructor
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var ListItemView = function(cocoaObject, parent, elementTag)
{
    this.parent = parent;

    this.cocoaObject = cocoaObject;

    this.element = document.createElement(elementTag);
    this.element.className = "item";

    this.isAttached = false;
}

ListItemView.prototype = {
    /**
     * @param {Node=} parentElement
     */
    attach: function(parentElement)
    {
        console.assert(!this.isAttached, "shouldn't be attached");

        parentElement.appendChild(this.element);

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

    createSubElements: function()
    {
        // Override
    },
    appendSubElementsToNode: function(element)
    {
        // Override
    },
    _subElementsAttached: false,
    attachSubElementsIfNeeded: function()
    {
        if (!this._subElementsAttached) {
            this._subElementsAttached = true;

            var tmpElement = this.element.cloneNode(false);

            this.createSubElements();
            this.appendSubElementsToNode(tmpElement);
            this.element.parentNode.replaceChild(tmpElement, this.element);
            this.element = tmpElement;
        }
    },

    set visible(visible)
    {
        console.assert(this.isAttached);

        if (this._visible == visible)
            return;

        this._visible = visible;
        if (visible) {
            this.attachSubElementsIfNeeded();
            this.element.addEventListener('mousedown', this.mouseDown.bind(this), false);
            this.element.addEventListener('click', this.mouseClicked.bind(this), false);
            this.element.addEventListener('dblclick', this.mouseDoubleClicked.bind(this), false);
            this.element.addEventListener('dragstart', this.dragStarted.bind(this), false);
            this.element.addEventListener('dragend', this.dragStarted.bind(this), false);
        }
    },

    /**
     * Event Handler
     * @param {Event} event
     */
    dragStarted: function(event)
    {
        event.dataTransfer.effectAllowed = "all";
        var items = [];
        for (var i = 0; i < this.parent.selection.length; i++)
            items.push(this.parent.selection[i].cocoaObject);
        window.dragData = items;
    },

    /**
     * Event Handler
     * @param {Event} event
     */
    dragEnded: function(event)
    {
        window.dragData = null;
    },

    /**
     * Event Handler
     * @param {Event} event
     */
    mouseDown: function(event)
    {
        if (!this.parent)
            return;

        if (event.shiftKey == 1)
            this.parent.selectTo(this);
        else if (event.metaKey)
            this.parent.toggleItemSelection(this);
        else if (!this.parent.doesSelectionContain(this))
            this.parent.select(this);
        event.stopPropagation();
    },
    mouseClicked: function(event)
    {
        if (!this.parent)
            return;

        if (event.shiftKey == 1)
            ;
        else if (event.metaKey)
            ;
        else
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
    }
};

ListItemView.prototype.detach.displayName = "ListItemView.detach()";
ListItemView.prototype.attach.displayName = "ListItemView.attach()";
ListItemView.prototype.__lookupSetter__("visible").displayName = "ListItemView.setVisible()";

