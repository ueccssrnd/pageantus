var Pageantus = {
    initialize: function(){
        
        Pageantus.AJAX.setup();
        Pageantus.AJAX.getTime();
        Pageantus.AJAX.getCandidates();
        Pageantus.UI.build();
        Pageantus.bindEvents();
    },
    bindEvents: function(){
        window.oncontextmenu = function(){
            return false;
        };
        $('#lock').click(Pageantus.UI.lockScreen);
        onresize = function(){
            Pageantus.UI.verticallyCenter('#candidate-details .image','#candidate-details',$(document).height()-245,'padding');
        };
        $('#candidateMenu').click(Pageantus.UI.toggleCandidate);
        $('#messageMenu').click(Pageantus.UI.toggleMessages);
        $('#categoryMenu').click(Pageantus.UI.toggleCategory);
        $('#btnSendMessage').click(Pageantus.AJAX.sendMessage);
        $('#btnSendCategory').click(Pageantus.AJAX.sendCategory);
    }
}

Pageantus.Variables = {
    min: 75,
    max: 100,
    categories: [],
    candidates: [],
    current: -1,
    connected: true,
    candidate: true,
    messages: true,
    baseURL: 'http://localhost/pageantus',
    userID: 1
}

Pageantus.UI = {
    build: function(){
        $('#dock2').Fisheye({
            maxWidth: 30,
            items: 'a',
            itemsText: 'span',
            container: '.dock-container2',
            itemWidth: 60,
            proximity: 80,
            alignment : 'left',
            valign: 'bottom',
            halign : 'center'
        });
        $('.panel').draggable(
        {
            containment: '#content-pane',
            stack: '.panel'
        });
//        Pageantus.UI.randomizeWallpaper();
        Pageantus.UI.slideToUnlock();
        Pageantus.UI.verticallyCenter('#candidate-details .image','#candidate-details',$(document).height()-245,'padding');
    },
    toggleCandidate: function(){
        if(Pageantus.Variables.candidate){
            $('.candidate').fadeIn();
            $('#sidebar').animate({width:'show'});
            Pageantus.Variables.candidate = false;
        }
        else{
            $('.candidate').fadeOut();
            $('#sidebar').animate({width:'hide'});
            Pageantus.Variables.candidate = true;
        }
    },
    toggleMessages: function(){
        if(Pageantus.Variables.messages){
            $('#messages').fadeIn();
            Pageantus.Variables.messages= false;
        }
        else{
            $('#messages').fadeOut();
            Pageantus.Variables.messages= true;
        }
    },
    lockScreen: function(){
        $('#header').css('top','-32px');
        $('#sidebar').hide();
        $('#content-pane').hide();
        $('#idle').fadeIn();
    },
    randomizeWallpaper: function(){
        var num = Math.ceil(Math.random(1,14)*100)%13+1;
        document.getElementsByTagName('body')[0].style.backgroundImage = 'url(public/images/background/m'+num+'.jpg)';
    },
    verticallyCenter: function(child, parent, parentHeight, attr){
        var marginTop = 0;
        if(parentHeight==undefined)
            parentHeight = $(parent).innerHeight();
        marginTop = parentHeight/2-$(child).innerHeight()/2;
        if(marginTop<0)
            marginTop = 0;
        switch(attr){
            case 'padding':
                $(parent).css({
                    'padding-top': marginTop+'px'
                    });
                break;
            default:
                $(child).css({
                    'margin-top': marginTop+'px'
                    });
                break;
        }
    },
    slideToUnlock: function(){
        $("#slider").draggable({
            axis: 'x',
            containment: 'parent',
            drag: function(event, ui) {
                if (ui.position.left > 370) {
                    $('#idle').fadeOut();
                    setTimeout(function(){
                        $('#header').animate({
                            top:0
                        },200,
                            function(){
                                $('#content-pane').fadeIn('slow');
                            });
                    },600);
                //Pageantus.Dialog.show('confirm','Welcome','The quick brown fox jumps over the lazy dog sitting under the old oak tree.');
                } else {
                    $("h2 span").css("opacity", 100 - (ui.position.left / 5))
                }
            },
            stop: function(event, ui) {
                $(this).animate({
                    left: 0
                })
            }
        });
    },
    listCandidates: function(){
        var candidates = Pageantus.Variables.candidates;
        for(var i=0;i<candidates.length;i++){
            $('#sidebar').append('<div class="candidate" id="'+i+'">'
                +'<span class="image">'
                +'<span class="number">'+candidates[i].candidate_number+'</span>'
                +'</span>'
                +'<span class="name">'+candidates[i].first_name+' '+
                candidates[i].last_name+'</span>'
                +'<span class="score"></span>'
                +'</div>');
            $('#'+i+' .image').css('background-image','url(public/images/candidates/'+candidates[i].portrait_picture_file+')');
        }
    }
}

Pageantus.AJAX = {
    setup: function(){
        $.ajaxSetup({
            method: 'GET',
            dataType: 'json',
            error: function(){
                Pageantus.Dialog.show('alert','Server Error','Oops! An error in connection occured.<br />Please try again later.');
                Pageantus.Variables.connected = false;
                $('#connectivity').css('background-position','-26px 0px');
            }
        });
    },
    sendCategory: function(){
        if($('#txtKeyword').val().trim()!=''){
            $.ajax({
                url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges/',
                data: {
                    request: 'currentCategory',
                    parameters:  JSON.stringify({request: $('#txtKeyword').val()})
                },                
                dataType:'json',
                success: function(data){
                    alert(data);
                    $('#txtKeyword').text('').focus();
                },
                error : function(data){
                  alert(data);  
                }
            });
        }
        else{
            $('#txtKeyword').focus();
        }
    },
    sendMessage: function(){
        if($('#txtTitle').val().trim()!=''){
            if($('#txtMessage').val().trim()!=''){
                $.ajax({
                    url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges/',
                    data: {
                        request: 'message',
                        parameters: JSON.stringify({
                            title: $('#txtTitle').val().trim(),
                            message: $('#txtMessage').val().trim()
                        })
                    },
                    success: function(){
                        $('#txtMessage').val('');
                        $('#btnSent').css('visibility','visible');
                        $('#btnSendMessage').hide();
                        setTimeout(function(){
                            $('#btnSent').css('visibility','hidden');
                            $('#btnSendMessage').show();
                        },2500);
						$('#txtMessage').focus();
                    }
                });
            }
            else{
                $('#txtMessage').focus();
            }
        }
        else{
            $('#txtTitle').focus();
        }
    },
    getCategory: function(){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges/',
            data: {
                request: 'category',
                parameters: 'prepageant'
            },
            success: function(data){
                Pageantus.AJAX.getCandidates();
                Pageantus.Variables.categories = data;
                for(var i=0;i<data.length;i++){
                    $('#criteria').append(
                        '<div class="criterion">'
                        +'<span class="category label">'
                        +data[i].category_name+'</span>'
                        +'<span name="'+i+'" class="score"></span>'
                        +'</div>');
                }
            }
        });
    },
    getTime: function(){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges/',
            data: {
                request: 'time',
                parameters: ''
            },
            success: function(data){
                $('#time div:eq(0)').text(data.time);
                $('#time div:eq(1)').text(data.date);
                $('#time').fadeIn();
                $('#unlock').fadeIn();
                $('#header span:eq(1)').text(data.time+' '+data.meridian);
                Pageantus.Variables.connected = true;
                $('#connectivity').css('background-position','0px 0px');
            }
        });
        setTimeout(Pageantus.AJAX.getTime,30000);
    },
    getCandidates: function(){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges',
            data: {
                request: 'candidates',
                parameters: JSON.stringify({                          
                    keyword: 'all'
                })
            },
            success: function(data){
                Pageantus.Variables.candidates = data;
                Pageantus.UI.listCandidates();
                Pageantus.Variables.connected = true;
                $('#connectivity').css('background-position','0px 0px');
            }
        });
    },
    getCurrent: function(){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges/',
            data: {
                request: 'candidates'
            },
            success: function(data){
                Pageantus.Variables.candidates = data;
                Pageantus.UI.listCandidates();
                Pageantus.Variables.connected = true;
                $('#connectivity').css('background-position','0px 0px');
            }
        });
    },
    getMessage: function(){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges/',
            data: {
                request: 'message'
            },
            success: function(data){
                if(data.title!=Pageantus.Variables.message.title){
                    if(data.message!=Pageantus.Variables.message.message){
                        Pageantus.Variables.message = data;
                        Pageantus.Dialog.show('alert',data.title,data.message);
                    }
                }
                Pageantus.Variables.connected = true;
                $('#connectivity').css('background-position','0px 0px');
            }
        });
        setTimeout(Pageantus.AJAX.getMessage,5000);
    }
}

Pageantus.Dialog = {
    show: function(type,title,message,accept,reject){
        //if an instance of the dialog is already
        //existing,remove it from the DOM
        if($('body').has('#dialogOverlay'))
            $('#dialogOverlay').remove();
        //avoiding undefined event handlers
        if(accept===undefined)
            accept = function(){};
        if(reject===undefined)
            reject = accept;
        if(type===undefined)
            type = '';
        if(title===undefined)
            title = '';
        if(message===undefined)
            message = ''
        //method overloading
        if(arguments.length==1&&arguments[0].constructor==String){
            message = arguments[0];
            title = Pageantus.title;
            type = 'alert';
        }
        else{
            if(type!=='confirm')
                type = 'alert';
            if(title.trim()==='')
                title = Pageantus.title;
            if(message.trim()==='')
                message = '';
        }
        //create dialog box
        $('body').append('<div id="dialogOverlay"><div class="dialogBox"><div class="dialogTitle">'+title+'</div><div class="dialogMessage">'+message+'</div><div class="dialogButtons"></div></div></div>');
        //buttons and event binding
        $('.dialogButtons').append('<input type="button" value="Okay" class="dialogOkay" />');
        $('.dialogOkay').click(function(){
            Pageantus.Dialog.hide(accept);
        });
        if(type==='confirm'){
            $('.dialogButtons').append('<input type="button" value="Cancel" class="dialogCancel" />');
            $('.dialogCancel').click(function(){
                Pageantus.Dialog.hide(reject);
            });
        }
        //fade in dialog box
        $('#dialogOverlay').fadeIn('fast');
        $(".dialogBox").draggable({
            containment:'window'
        });
    },
    hide: function(callback){
        //fade out dialog box
        $('#dialogOverlay').fadeOut('fast');
        //execute callback function if it exists
        if(callback!==null)
            callback();
        //remove dialog elements from the DOM
        setTimeout(function(){
            $('#dialogOverlay').remove();
        },500);
    }
};

$(document).ready(Pageantus.initialize);