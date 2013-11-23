var myApp = angular.module("myApp", []);
myApp.factory("Data", function() {
    return {message: "I'm a data from a service"};
})

myApp.filter('reverse', function() {
    return function(text) {
        return text.split("").reverse().join("");
    }
})

function FirstCtrl($scope, Data) {
    $scope.data = Data;
}

function SecondCtrl($scope, Data) {
    $scope.data = Data;

    $scope.reversedMessage = function(message) {
        return message.split("").reverse().join("");
    }
}


myApp.factory("Avengers", function() {
    var Avengers = {}

    Avengers.cast = [
        {
            name: "me",
            character: "meme"
        },
        {
            name: "mo",
            character: "meoe"
        },
        {
            name: "yo",
            character: "yod"
        }
    ]
    return Avengers;
})

function AvengersCtrl($scope, Avengers){
    $scope.avengers = Avengers;
}