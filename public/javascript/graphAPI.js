var nodes = "";
var edges = "";
var currentNodeIDs = []; //the list of frontier nodes waiting to be expanded
var existingNodeIDs = []; //to check if node already exists before inserting
var fullGraphLoaded = false;
var network = "";

$(document).ready(function() {
    //initialization
    startGraph();
    setNetworkMenu();
    setNetworkEdge();
});

var options = {
    "edges": {
        "smooth": false
    },
    layout: {
        improvedLayout: true,
        hierarchical: {
            enabled: false,
            parentCentralization: false,
            blockShifting: false,
            edgeMinimization: false,
            sortMethod: 'hubsize',
            direction: 'LR'
        }
    },
    nodes: {
        size: 35,
        color: {
            border: '#000',
            background: '#fff',
            highlight: {
                border: '#000',
                background: '#fff'
            },
            hover: {
                border: '#6BA368',
                background: '#D2E5FF'
            }
        },
        font: {
            color: '#000',
            size: 14, //px
            strokeColor: '#fff',
            align: 'center'
        },
        shape: 'circle'
    },
    "physics": {
        "forceAtlas2Based": {
            "gravitationalConstant": -394,
            "springLength": 100,
            "springConstant": 0.165,
            "damping": 0.22,
            "avoidOverlap": 0.77
        },
        "maxVelocity": 150,
        "minVelocity": 5.39,
        "solver": "forceAtlas2Based"
    }
};



function startGraph() {
    nodes = new vis.DataSet();
    edges = new vis.DataSet();
    var data = {
        nodes: nodes,
        edges: edges
    };

    var container = document.getElementById('mynetwork');
    network = new vis.Network(container, data, options);
}

function setNetworkEdge() {

    //this first bit is to update the label on the selected edge
    var currentEdgeID = "";
    network.on('selectEdge', function(params) {
        currentEdgeID = params.edges[0];
        var xhttp = new XMLHttpRequest();
        xhttp.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 200) {
                edgeLabel = JSON.parse(this.responseText);
                edges.update({ id: params.edges[0], label: '(' + edgeLabel.action + ',' + edgeLabel.binding + ')' });
            }
        }
        xhttp.open("post", "/getEdgeLabel", true);
        xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        xhttp.send('from=' + edges.get(params.edges[0]).from + '&to=' + edges.get(params.edges[0]).to);
    });

    //this second bit is to show it on the panel
    network.on('selectEdge', function(params) {
        var xhttp = new XMLHttpRequest();
        xhttp.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 200) {
                bindingInfo = JSON.parse(this.responseText);
                var html = "";
                for (var field in bindingInfo) {
                    html = html + '<p>' + field + ': ' + bindingInfo[field] + '</p>'
                }
                $('#bindingInformation').html(html);
            }
        }
        xhttp.open("post", "/getBindingInfo", true);
        xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        xhttp.send('from=' + edges.get(params.edges[0]).from + '&to=' + edges.get(params.edges[0]).to);
    });

    //this resets the labels edge and panel
    network.on('deselectEdge', function(params) {
        edges.update({ id: currentEdgeID, label: '' });
        $('#bindingInformation').html('');
    });
}


function clusterByAction() {
    var actions = ['startw', 'rvwreq', 'fillrmb', 'endw', 'revwreimb']; //query db
    var clusterOptionsByAction;
    for (var i = 0; i < actions.length; i++) {
        var action = actions[i];
        clusterOptionsByAction = {
            joinCondition: function(childOptions) {
                return childOptions.group == action;
            },
            processProperties: function(clusterOptions, childNodes, childEdges) {
                var totalMass = 0;
                for (var i = 0; i < childNodes.length; i++) {
                    totalMass += childNodes[i].mass;
                }
                clusterOptions.mass = totalMass;
                clusterOptions.physics = false;
                return clusterOptions;
            },
            clusterNodeProperties: { id: action, label: action }
        };
        network.cluster(clusterOptionsByAction);
    }
    // network.setOptions(options = {
    //   "edges": {
    //     "smooth": true
    //   },
    //   "physics": {
    //     stabilizations:true,
    //     // "enabled": false,
    //     "minVelocity": 1
    //   }
    // });
    network.on("selectNode", function(params) {
        if (params.nodes.length == 1) {
            if (network.isCluster(params.nodes[0]) == true) {
                network.openCluster(params.nodes[0]);
            }
        }
    });
}

function setNetworkMenu() {
    network.on('click', function(params) {
        $('#menu').hide();
        $('#clickedNode').text("Selected node " + params.nodes);
    });
    network.on("oncontext", function(params) {

        $("#mynetwork").contextmenu(function() {
            return false;
        });

        var menu = $('#menu');

        //hide menu if already shown
        menu.hide();
        console.log(params.pointer.DOM);
        //get x and y values of the click event
        var pageX = params.pointer.DOM.x;
        var pageY = params.pointer.DOM.y;


        //position menu div near mouse cliked area
        menu.css({ top: pageY, left: pageX });
        var mwidth = menu.width();
        var mheight = menu.height();
        var screenWidth = $(window).width();
        var screenHeight = $(window).height();

        //if window is scrolled
        var scrTop = $(window).scrollTop();

        //if the menu is close to right edge of the window
        if (pageX + mwidth > screenWidth) {
            menu.css({ left: pageX - mwidth });
        }

        //if the menu is close to bottom edge of the window
        if (pageY + mheight > screenHeight + scrTop) {
            menu.css({ top: pageY - mheight });
        }

        try {
            theNode = network.getNodeAt(params.pointer.DOM);
            $('#firstMenuItem').text("Node: " + theNode);
            $('#clickedNode').text("Selected node: " + theNode);
            $('#secondMenuItem').text("Copy");
            $('#thirdMenuItem').text("Edit");
            $('#fourthMenuItem').text("Inspect");
            network.selectNodes([theNode]);
        } catch (e) {
            console.log("No node here.");
            $('#firstMenuItem').text("Stub");
            $('#secondMenuItem').text("Stub");
            $('#thirdMenuItem').text("Stub");
            $('#fourthMenuItem').text("Stub");
        } finally {

        }
        menu.show();
    });

}

function loadInitialState() {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            rootNode = JSON.parse(this.responseText);
            if (existingNodeIDs.length > 0) { //reseting graph
                nodes.clear();
                edges.clear();
                currentNodeIDs = [];
                existingNodeIDs = [];
            }
            nodes.add({ id: rootNode.curr, label: rootNode.curr, group: rootNode.action });
            currentNodeIDs.push(rootNode.curr);
            existingNodeIDs.push(rootNode.curr);
        }
    }
    xhttp.open("GET", "/loadInitialState", true);
    xhttp.send();
    fullGraphLoaded = false;
}

function removeDuplicates(arr) {
    let unique_array = []
    for (let i = 0; i < arr.length; i++) {
        if (unique_array.indexOf(arr[i]) == -1) {
            unique_array.push(arr[i])
        }
    }
    return unique_array
}

function loadFrontier() {
    if (fullGraphLoaded == false) {
        var xhttp = new XMLHttpRequest();
        xhttp.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 200) {
                var rows = JSON.parse(this.responseText);
                for (var i = 0, len = rows.length; i < len; i++) {
                    if (existingNodeIDs.indexOf(rows[i].next) == -1) {
                        console.log("pushing action on node: " + rows[i].action);
                        nodes.add({ id: rows[i].next, label: rows[i].next, group: rows[i].action });
                        currentNodeIDs.push(rows[i].next);
                        existingNodeIDs.push(rows[i].next);
                    }
                    edges.add({ from: rows[i].curr, to: rows[i].next, arrows: 'to' }); //, label: '('+rows[i].action+','+rows[i].binding+')'
                }
            }
        }
        xhttp.open("post", "/loadFrontier", true);
        xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        console.log("sending currentNodeIDs(unique): " + removeDuplicates(currentNodeIDs));
        xhttp.send('currentNodeID=' + removeDuplicates(currentNodeIDs)); //.pop()
        currentNodeIDs = [];
    } else {
        console.log("can't expand frontier with a full graph");
    }

}

function loadFullGraph() {
    console.time('fullGraph');
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            console.log(this.responseText);
            if (existingNodeIDs.length > 0) { //reseting graph
                nodes.clear();
                edges.clear();
                existingNodeIDs = [];
            }
            console.log('reset the graph successfully: ' + existingNodeIDs);
            var rows = JSON.parse(this.responseText);
            for (var i = 0, len = rows.length; i < len; i++) {
                if (existingNodeIDs.indexOf(rows[i].curr) == -1) {
                    nodes.add({ id: rows[i].curr, label: rows[i].curr, group: rows[i].action });
                    existingNodeIDs.push(rows[i].curr);
                    console.log(existingNodeIDs);
                }
                if (existingNodeIDs.indexOf(rows[i].next) == -1) {
                    nodes.add({ id: rows[i].next, label: rows[i].next, group: rows[i].action });
                    existingNodeIDs.push(rows[i].next);
                    console.log(existingNodeIDs);
                }
                edges.add({ from: rows[i].curr, to: rows[i].next, arrows: 'to' }); //, label: '('+rows[i].action+','+rows[i].binding+')'
            }
            console.timeEnd('fullGraph');
        }
    }
    xhttp.open("GET", "/loadFullGraph", true);
    xhttp.send();
    fullGraphLoaded = true;
}

function generatePDF() {

    html2canvas($("canvas")[0], {
        onrendered: function(canvas) {
            var imgData = canvas.toDataURL(
                'image/png');
            var doc = new jsPDF('p', 'mm');
            doc.addImage(imgData, 'PNG', 10, 10);
            doc.save('sample-file.pdf');
        }
    });

    //
    // var doc = new jsPDF();
    // var canvas = document.querySelector('canvas');
    // var imgData = canvas.toDataURL("image/jpeg", 1.0);
    // doc.addImage(imgData, 'JPEG', 0, 0);
    // doc.save('TSgraph.pdf');
}