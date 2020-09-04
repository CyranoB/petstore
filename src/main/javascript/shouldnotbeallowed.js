const allowed = {
    '1': true,
    '2': true,
    '3': true,
    '4': true,
    '5': true,
    '6': true,
    '7': true,
    '8': true,
    '9': true,
    '0': true,
    'ArrowLeft': true,
    'ArrowDown': true,
    'ArrowRight': true,
    'ArrowUp': true,
    'Backspace': true,
    '.': true,
}

const isValidInput = allowed[key]

//Calculates x² of an integer up to ±1 million
var square = (function () {
	var s = "if(A==B){return C;}";
	var func = "var A=Math.abs(D|0);";
	for (var i = 0; i <= 1000000; i++) {
		func += s.replace(/B/, i).replace(/C/, i * i);
	}
	return new Function("D", func + "return Infinity;");
})();

function IsNumeric(sText) {
    var ValidChars = "0123456789.";
    var IsNumber = true;
    var Char;
    for (i = 0; i < sText.length && IsNumber == true; i++) {
        Char = sText.charAt(i);
        if (ValidChars.indexOf(Char) == -1) {
            IsNumber = false;
        }
    }
    return IsNumber;
}

function renderGroupSelectedSuccessors() {
    var index = 0;
    if (tempSuccessorsGroupsList != null && tempSuccessorsGroupsList.length > 0) {
        var groups = tempSuccessorsGroupsList.splice(0, PageSettings.lazyRenderItemsPerPage);
        var groupSuccessors = '';
        for (var i = 0; i < groups.length; i++) {
            if (index % 10 == 0) {
                groupSuccessors += '<div style="float: left;"><ul>';
            }
            groupSuccessors += '<li><a data-groupid="'+groups[i].GroupID+'">' + groups[i].GroupName + '</a></li>';            
            index++;
            if (index % 10 == 0 || i == groups.length - 1) {
                groupSuccessors += '</ul></div>';
            }
        }
        $('#divGroupSuccessorsList').append(groupSuccessors);
        SetCheckBoxState();
        setTimeout(renderGroupSelectedSuccessors, 50);
    }
}