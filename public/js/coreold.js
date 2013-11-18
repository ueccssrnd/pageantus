var Pageantus = {
    initialize: function(){
        Pageantus.AJAX.setup();
        Pageantus.AJAX.getCategoryID();
        Pageantus.AJAX.getUserID();
        Pageantus.AJAX.getTime();
        Pageantus.AJAX.getMessage();
        Pageantus.UI.build();
        Pageantus.bindEvents();
    },
    bindEvents: function(){
        window.oncontextmenu = function(){
            return false;
        };
        $('#lock').click(Pageantus.UI.lockScreen);
        onresize = Pageantus.UI.centerCandidateDetails;
        $('.left').click(function(){
            Pageantus.UI.showCandidate(Pageantus.Variables.current-1)
            });
        $('.right').click(function(){
            Pageantus.UI.showCandidate(Pageantus.Variables.current+1)
            });
        $('#submit').click(Pageantus.AJAX.submitScores);
        $('#settings').click(Pageantus.UI.showSettings);
    }
}

Pageantus.Variables = {
    min: 75,
    max: 100,
    categories: [],
    candidates: [],
    results: [],
    current: -1,
    connected: true,
    message: '',
    baseURL: 'http://localhost/pageantus',
    userID: '',
    Current: {
        candidate: -1,
        category: -1
    },
    submitted: false,
    toSubmit: 0
}

Pageantus.UI = {
    build: function(){
        //        Pageantus.UI.randomizeWallpaper();
        Pageantus.UI.slideToUnlock();
        Pageantus.UI.centerCandidateDetails();
    },
    toggleBottomPane: function(flag){
        if(flag){
            $('#candidate-set').slideDown();
            $('#candidate-details').animate({
                bottom:'155px'
            },function(){
                Pageantus.UI.verticallyCenter('#candidate-details .image',
                    '#candidate-details',$(document).height()-245,'padding');
            });
        }
        else{
            $('#candidate-set').slideUp();
            $('#candidate-details').animate({
                bottom:0
            },Pageantus.UI.centerCandidateDetails);
        }
    },
    showSettings: function(){
        var html = '<input id="txtUserID" placeholder="User ID" value="'+
        Pageantus.Variables.userID+'" type="text" />'+
        '<input id="txtBaseURL" value="'+Pageantus.Variables.baseURL+
        '" placeholder="Base URL" type="text" />';
        Pageantus.Dialog.show('alert','System Settings',html,
            function(){
                Pageantus.Variables.baseURL = $('#txtBaseURL').val();
                if(Pageantus.Variables.userID!=$('#txtUserID').val()){
                    Pageantus.Variables.userID = $('#txtUserID').val();
                    Pageantus.AJAX.setUserID(Pageantus.Variables.userID);
                }
            });
    },
    centerCandidateDetails: function(){
        Pageantus.UI.verticallyCenter('#candidate-details .image','#candidate-details',$(document).height()-120,'padding');
    },
    initSliders: function(){
        var sliderOptions = {
            min: Pageantus.Variables.min,
            max: Pageantus.Variables.max,
            step: 1,
            slide: function(event,ui){
                $(this).children('.fill').css('width',(ui.value-75)*4+'%').addClass('changed');
                $(this).children('.ui-slider-handle').text(ui.value).addClass('changed');
                if($(this).attr('id')==Pageantus.Variables.current){
                    var position = 350-(Pageantus.Variables.max-ui.value)/(Pageantus.Variables.max-Pageantus.Variables.min)*350;
                    $('#score .ui-slider-handle').text(ui.value).css('left',position);
                    $('#score .fill').css('width',(ui.value-75)*4+'%');
                }
                Pageantus.Variables.results[$(this).attr('id')][0].score = ui.value;
                Pageantus.UI.showCandidate($(this).attr('id'));
                if(Pageantus.Variables.categories.length==1)
                    if(($('.candidate .changed').length/2==Pageantus.Variables.candidates.length)&&Pageantus.Variables.toSubmit>0)
                        Pageantus.UI.toggleBottomPane(true);
            }
        };
        $('.candidate .score').slider(sliderOptions);
        sliderOptions.slide = function(event,ui){
            $(this).children('.fill').css('width',(ui.value-75)*4+'%').addClass('changed');
            $(this).children('.ui-slider-handle').text(ui.value).addClass('changed');
            Pageantus.Variables.results[Pageantus.Variables.current][$(this).attr('name')].score = ui.value;
        }
        $('#criteria .score').slider(sliderOptions);
        sliderOptions.slide = function(event,ui){
            $(this).children('.fill').css('width',(ui.value-75)*4+'%');
            $(this).children('.ui-slider-handle').text(ui.value);
            var position = 200-(Pageantus.Variables.max-ui.value)/(Pageantus.Variables.max-Pageantus.Variables.min)*200;
            $('#'+Pageantus.Variables.current+' .ui-slider-handle').text(ui.value).addClass('changed').css('left',position);
            $('#'+Pageantus.Variables.current+' .fill').css('width',(ui.value-75)*4+'%').addClass('changed');
            Pageantus.Variables.results[Pageantus.Variables.current][0].score = ui.value;
            if(Pageantus.Variables.categories.length==1)
                if(($('.candidate .changed').length/2==Pageantus.Variables.candidates.length)&&Pageantus.Variables.toSubmit>0)
                    Pageantus.UI.toggleBottomPane(true);
        };
        $('#score').slider(sliderOptions);
        $('.score').prepend('<span class="fill"></span>').slider('enable');
        $('.ui-slider-handle').text(75);
        $('.candidate').click(function(){
            Pageantus.UI.showCandidate($(this).children('.score').attr('id'));
        });
        //        $('.candidate .ui-slider-handle').click(function(){Pageantus.UI.showCandidate($(this).parent().attr('id'));});
        Pageantus.UI.toggleCriteria(Pageantus.Variables.categories.length>1);
        Pageantus.UI.showCandidate(0);
        Pageantus.AJAX.toSubmit();
    },
    toggleCriteria: function(flag){
        if(flag){
            $('#criteria').animate({
                'width':'show'
            });
            $('#candidate-details').animate({
                'left':'280px'
            });
            $('#candidate-set').animate({
                'left':'280px'
            });
            $('.score-pane').css({
                'visibility':'hidden'
            });
            $('.candidate .name').css({
                'top':'25px'
            });
            $('.candidate .score').css({
                'visibility':'hidden'
            });
        }
        else{
            $('#criteria').animate({
                width:'hide'
            });
            $('#candidate-details').animate({
                'left':'0'
            });
            $('#candidate-set').animate({
                'left':'0'
            });
            $('.score-pane').css({
                'visibility':'visible'
            });
            $('.candidate .name').css({
                'top':'10px'
            });
            $('.candidate .score').css({
                'visibility':'visible'
            });
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
                $(parent).animate({
                    'padding-top': marginTop+'px'
                    });
                break;
            default:
                $(child).animate({
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
                            $('#sidebar').fadeIn('slow',
                                function(){
                                    $('#content-pane').fadeIn('slow');
                                });
                        });
                    },600);
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
        $('#sidebar').text('');
        Pageantus.Variables.results = [];
        var candidates = Pageantus.Variables.candidates;
        for(var i=0;i<candidates.length;i++){
            $('#sidebar').append('<div class="candidate">'
                +'<span class="image">'
                +'<span class="number">'+candidates[i].candidate_number+'</span>'
                +'</span><input type="hidden" class="candidate-id" value="'+candidates[i].candidate_id+'" />'
                +'<span class="name">'+candidates[i].first_name+' '+
                candidates[i].last_name+'</span>'
                +'<span class="score" id="'+i+'"></span>'
                +'</div>');
            $('.candidate:eq('+i+') .image').css('background-image','url(public/images/candidates/'+candidates[i].portrait_picture_file+')');
            var categories = Pageantus.Variables.categories;
            var candidateSet = [];
            for(var j=0;j<categories.length;j++){
                candidateSet.push({
                    user_id: Pageantus.Variables.userID,
                    category_id: categories[j].category_id,
                    candidate_id: parseInt(candidates[i].candidate_id),
                    score: 75
                });
            }
            Pageantus.Variables.results.push(candidateSet);
        }
        Pageantus.UI.initSliders();
        $('#sidebar').animate({
            scrollTop:'0px'
        },'slow');
    },
    showCandidate: function(i){
        if(i<0)
            i = 0;
        if(i>Pageantus.Variables.candidates.length-1)
            i = Pageantus.Variables.candidates.length-1;
        
        Pageantus.Variables.current = parseInt(i);
        
        var val = $('#sidebar .candidate:eq('+i+') .ui-slider-handle').text();
        var position = 350-(Pageantus.Variables.max-val)/(Pageantus.Variables.max-Pageantus.Variables.min)*350;
        $('#score .ui-slider-handle').text(val);
        $('#score .ui-slider-handle').css('left',position);
        $('#score .fill').css('width',(val-75)*4+'%');
        
        var c = Pageantus.Variables.candidates[i];
        $('#candidate-details .number').text(c.candidate_number);
        $('#candidate-details .name').text(c.first_name+' '+c.last_name);
        $('#candidate-details .college').text(c.college_name);
        $('#candidate-details .image').css('background-image','url(public/images/candidates/'+c.full_body_picture_file+')');
        
        for(var j=0;j<Pageantus.Variables.categories.length;j++){
            val = Pageantus.Variables.results[Pageantus.Variables.current][j].score;
            position = 210-(Pageantus.Variables.max-val)/(Pageantus.Variables.max-Pageantus.Variables.min)*210;
            $('.criterion:eq('+j+') .fill').css('width',(val-75)*4+'%');
            $('.criterion:eq('+j+') .ui-slider-handle').text(val).css('left',position);
            if(val==Pageantus.Variables.min){
                $('.criterion:eq('+j+') .fill').removeClass('changed');
                $('.criterion:eq('+j+') .ui-slider-handle').removeClass('changed');
            }
            else{
                $('.criterion:eq('+j+') .fill').addClass('changed');
                $('.criterion:eq('+j+') .ui-slider-handle').addClass('changed');
            }
        }
    }
}

Pageantus.AJAX = {
    setup: function(){
        $.ajaxSetup({
            method: 'GET',
            dataType: 'json',
            error: function(){
                Pageantus.Variables.connected = false;
                $('#connectivity').css('background-position','-26px 0px');
            }
        });
    },
    getUserID: function(){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/getSessionInformation',
            dataType:'text',
            success: function(data){
                Pageantus.Variables.userID = data;
                if(Pageantus.Variables.userID == ''){
                    Pageantus.UI.showSettings();
                }
            }
        });
    },
    setUserID: function(user_id){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/validate',
            data: {
                user_id: user_id
            },
            dataType:'text',
            success: function(){
                Pageantus.AJAX.getUserID();
            }
        });
    },
    toSubmit: function(){
        $.ajax({
            //change this!
            url: 'http://192.168.1.1/pageanta/toSubmit.php',
//            url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges',
            success: function(data){
                if(data!=Pageantus.Variables.toSubmit){
                    Pageantus.Variables.toSubmit = data;
                    if(data==1){
                        if(Pageantus.Variables.categories.length==1){
                            if($('.candidate .changed').length/2==Pageantus.Variables.candidates.length)
                                Pageantus.UI.toggleBottomPane(true);
                        }
                        else
                            Pageantus.UI.toggleBottomPane(true);
                    }
                    else{
                        Pageantus.UI.toggleBottomPane(false);
                    }
                }
            }
        });
        if(!Pageantus.Variables.submitted)
            setTimeout(Pageantus.AJAX.toSubmit,5000);
    },
    getCategory: function(){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges',
            data: {
                request: 'category',
                parameters: JSON.stringify({                     
                    keyword: Pageantus.Variables.Current.category
                })
            },
            success: function(data){
                Pageantus.AJAX.getCandidates();
                Pageantus.Variables.categories = data;
                if(data.length>1){
                    $('#criteria').text('');
                    Pageantus.UI.toggleCriteria(true);
                    for(var i=0;i<data.length;i++){
                        $('#criteria').append(
                            '<div class="criterion">'
                            +'<span class="category label">'
                            +data[i].category_name+'</span>'
                            +'<span name="'+i+'" class="score"></span>'
                            +'</div>');
                    }
                }
                else{
                    Pageantus.UI.toggleCriteria(false);
                    $('.category.label').text(data[0].category_name);
                }
                Pageantus.Variables.submitted = false;
            }
        });
    },
    
    getTime: function(){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges',
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
                    keyword: (Pageantus.Variables.Current.category=='final'?'final':'all')
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
            url: Pageantus.Variables.baseURL+'/index.php/main/adminSendsToJudges',
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
            url: Pageantus.Variables.baseURL+'/index.php/main/judgeReadsFromAdmin',
            data: {
                request: 'message'
            },
            success: function(data){
                if(data.message!==Pageantus.Variables.message){
                    if(Pageantus.Variables.message!=='')
                        Pageantus.Dialog.show('alert',data.title,data.message);
                    Pageantus.Variables.message = data.message;
                }
                Pageantus.Variables.connected = true;
                $('#connectivity').css('background-position','0px 0px');
            }
        });
        setTimeout(Pageantus.AJAX.getMessage,5000);
    },
    getCategoryID: function(){
        $.ajax({
            url: Pageantus.Variables.baseURL+'/index.php/main/judgeReadsFromAdmin',
            dataType: 'text',
            data: {
                request: 'currentCategory'
            },
            success: function(data){
                if(data!=Pageantus.Variables.Current.category){
                    Pageantus.Variables.Current.category = data;
                    Pageantus.AJAX.getCategory();
                }
            }
        });
        setTimeout(Pageantus.AJAX.getCategoryID,5000);
    },
    submitScores: function(){
        if(Pageantus.Variables.userID!=''){
            Pageantus.Dialog.show('confirm','Confirm Score Submission','Are you sure you want to submit votes for this category? This step cannot be undone.',
                function(){
                    var results = Pageantus.Variables.results;
                    $.ajax({
                        url: Pageantus.Variables.baseURL+'/index.php/main/judgeSendsScores',
                        data: {
                            parameters: JSON.stringify(results)
                        },
                        success: function(){
                            Pageantus.Variables.submitted = true;
                            Pageantus.Variables.connected = true;
                            $('#connectivity').css('background-position','0px 0px');
                            Pageantus.UI.toggleBottomPane(false);
                            $('.score').slider('disable');
                            setTimeout(function(){
                                Pageantus.Dialog.show('alert','Submission Successful',
                                    'Scores have been successfully submitted.');
                            },800);
                        }
                    });
                },function(){});
        }
        else{
            Pageantus.UI.showSettings();
        }
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