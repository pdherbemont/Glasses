function togglePlaylistView()
{
    var name = "show-playlist";
    if (!document.body.hasClassName(name)) {
        document.getElementById("more").addClassName("visible");
        document.body.addClassName(name);
    }
    else {
        document.getElementById("more").removeClassName("visible");
        document.body.removeClassName(name);
    }
    removeItems();
    addItems();
    window.PlatformView.videoDidResize();
}

function tableClicked(event)
{
    var object = null;
    if (this.tagName == "TD")
        object = this.parent;
    else if (this.tagName == "TR")
        object = this;
    if (!object)
        return;
    object.addClassName("selected")
}

var emptyItem = {
index: 0,
title: "No title",
artist: "No artist"
};

function initPlaylist()
{
    var playlist = document.getElementById("playlist");
    var table = createTableWithDiv(playlist);
    playlist.table = table;

    removeItems();
    setTimeout("addItems()", 0);
}

function newItem(index, title)
{
    return { index: index, title: title, artist: "" }
}

function addItems()
{
    var playlist = document.getElementById("playlist");
    var platformView = window.PlatformView;
    if (!platformView)
        return;
    for(i = 0; i < platformView.count(); i++)
        playlist.table.add(newItem(i, platformView.titleAtIndex_(i)));
}

function removeItems()
{
    var playlist = document.getElementById("playlist");
    playlist.innerHTML = "";
}

var selectedElement = null;
function itemClicked(event)
{
    if (selectedElement && selectedElement != this) {
        selectedElement.removeClassName("selected");
        selectedElement = null;
    }
    
    this.addClassName("selected");
    selectedElement = this;
}

function itemDoubleClicked(event)
{
    console.log("Double clicked " + this.media);
    window.PlatformView.playMediaAtIndex_(this.media.index);
}

function createTableWithDiv(div)
{
    var table = new Object();
    table.div = div;
    
    table.add = function(item) {
        var frag = document.createElement("li");
        frag.id = "tableItem" + item.index;
        frag.media = item;
        frag.onclick = itemClicked;
        frag.ondblclick = itemDoubleClicked;
        frag.innerHTML = "<div>"+item.title+"</div>";
        table.div.appendChild(frag);
    }
    
    table.remove = function(item) {
        var playlist = document.getElementById("playlist");
        var playlistItem = document.getElementById("tableItem" + item.index);
        playlist.removeChild(playlistItem);
        
    }
    return table;
}
