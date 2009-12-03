/**************************************************
 * dom-drag.js
 * 09.25.2001
 * www.youngpup.net
 **************************************************
 * 10.28.2001 - fixed minor bug where events
 * sometimes fired off the handle, not the root.
 **************************************************/

/**
 * @constructor
 */
var Drag = function ()
{
    
}

Drag.prototype = {
	
	obj : null,
    
    parseIntDec: function parseIntDec(a) {
        parseInt(a, 10);
    },
        
	init : function(o, oRoot, minX, maxX, minY, maxY, bSwapHorzRef, bSwapVertRef, fXMapper, fYMapper)
	{
		o.onmousedown	= this.start.bind(this);
		
		o.hmode			= bSwapHorzRef ? false : true ;
		o.vmode			= bSwapVertRef ? false : true ;
		
		o.root = oRoot && oRoot != null ? oRoot : o ;
		
		if (o.hmode  && isNaN(this.parseIntDec(o.root.style.left))) o.root.style.left   = "0px";
		if (o.vmode  && isNaN(this.parseIntDec(o.root.style.top))) o.root.style.top    = "0px";
		if (!o.hmode && isNaN(this.parseIntDec(o.root.style.right))) o.root.style.right  = "0px";
		if (!o.vmode && isNaN(this.parseIntDec(o.root.style.bottom))) o.root.style.bottom = "0px";
		
		o.minX	= typeof minX != 'undefined' ? minX : null;
		o.minY	= typeof minY != 'undefined' ? minY : null;
		o.maxX	= typeof maxX != 'undefined' ? maxX : null;
		o.maxY	= typeof maxY != 'undefined' ? maxY : null;
		
		o.xMapper = fXMapper ? fXMapper : null;
		o.yMapper = fYMapper ? fYMapper : null;
		
		o.root.onDragStart	= new Function();
		o.root.onDragEnd	= new Function();
		o.root.onDrag		= new Function();
	},
	
	start : function(e)
	{
		if (e.srcElement.nodeName != "DIV")
			return;
		
		var o = this.obj = e.currentTarget;
		e = this.fixE(e);
		var y = this.parseIntDec(o.vmode ? o.root.style.top  : o.root.style.bottom);
		var x = this.parseIntDec(o.hmode ? o.root.style.left : o.root.style.right );
		o.root.onDragStart(x, y);
		
		o.lastMouseX	= e.clientX;
		o.lastMouseY	= e.clientY;
		
		if (o.hmode) {
			if (o.minX != null)	o.minMouseX	= e.clientX - x + o.minX;
			if (o.maxX != null)	o.maxMouseX	= o.minMouseX + o.maxX - o.minX;
		} else {
			if (o.minX != null) o.maxMouseX = -o.minX + e.clientX + x;
			if (o.maxX != null) o.minMouseX = -o.maxX + e.clientX + x;
		}
		
		if (o.vmode) {
			if (o.minY != null)	o.minMouseY	= e.clientY - y + o.minY;
			if (o.maxY != null)	o.maxMouseY	= o.minMouseY + o.maxY - o.minY;
		} else {
			if (o.minY != null) o.maxMouseY = -o.minY + e.clientY + y;
			if (o.maxY != null) o.minMouseY = -o.maxY + e.clientY + y;
		}
		
		document.onmousemove	= this.drag.bind(this);
		document.onmouseup		= this.end.bind(this);
		
		return false;
	},
	
	drag : function(e)
	{
		e = this.fixE(e);
		var o = this.obj;
		
		var ey	= e.clientY;
		var ex	= e.clientX;
		var y = this.parseIntDec(o.vmode ? o.root.style.top  : o.root.style.bottom);
		var x = this.parseIntDec(o.hmode ? o.root.style.left : o.root.style.right );
		var nx, ny;
		
		if (o.minX != null) ex = o.hmode ? Math.max(ex, o.minMouseX) : Math.min(ex, o.maxMouseX);
		if (o.maxX != null) ex = o.hmode ? Math.min(ex, o.maxMouseX) : Math.max(ex, o.minMouseX);
		if (o.minY != null) ey = o.vmode ? Math.max(ey, o.minMouseY) : Math.min(ey, o.maxMouseY);
		if (o.maxY != null) ey = o.vmode ? Math.min(ey, o.maxMouseY) : Math.max(ey, o.minMouseY);
		
		nx = x + ((ex - o.lastMouseX) * (o.hmode ? 1 : -1));
		ny = y + ((ey - o.lastMouseY) * (o.vmode ? 1 : -1));
		
		if (o.xMapper)		nx = o.xMapper(y)
            else if (o.yMapper)	ny = o.yMapper(x)
				
				this.obj.root.style[o.hmode ? "left" : "right"] = nx + "px";
		this.obj.root.style[o.vmode ? "top" : "bottom"] = ny + "px";
		this.obj.lastMouseX	= ex;
		this.obj.lastMouseY	= ey;
		
		this.obj.root.onDrag(nx, ny);
		return false;
	},
	
	end : function()
	{
		document.onmousemove = null;
		document.onmouseup   = null;
		this.obj.root.onDragEnd(this.parseIntDec(this.obj.root.style[this.obj.hmode ? "left" : "right"]), 
								this.parseIntDec(this.obj.root.style[this.obj.vmode ? "top" : "bottom"]));
		this.obj = null;
	},
	
	fixE : function(e)
	{
		if (typeof e == 'undefined') e = window.event;
		if (typeof e.layerX == 'undefined') e.layerX = e.offsetX;
		if (typeof e.layerY == 'undefined') e.layerY = e.offsetY;
		return e;
	}
};

window.dragController = new Drag();
