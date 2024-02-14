import{dispatch as e}from"d3-dispatch";import{dragDisable as t,dragEnable as n}from"d3-drag";import{interpolate as r}from"d3-interpolate";import{select as u,pointer as i}from"d3-selection";import{interrupt as s}from"d3-transition";var constant=e=>()=>e;function BrushEvent(e,{sourceEvent:t,target:n,selection:r,mode:u,dispatch:i}){Object.defineProperties(this,{type:{value:e,enumerable:true,configurable:true},sourceEvent:{value:t,enumerable:true,configurable:true},target:{value:n,enumerable:true,configurable:true},selection:{value:r,enumerable:true,configurable:true},mode:{value:u,enumerable:true,configurable:true},_:{value:i}})}function nopropagation(e){e.stopImmediatePropagation()}function noevent(e){e.preventDefault();e.stopImmediatePropagation()}var o={name:"drag"},a={name:"space"},l={name:"handle"},c={name:"center"};const{abs:h,max:f,min:d}=Math;function number1(e){return[+e[0],+e[1]]}function number2(e){return[number1(e[0]),number1(e[1])]}var b={name:"x",handles:["w","e"].map(type),input:function(e,t){return null==e?null:[[+e[0],t[0][1]],[+e[1],t[1][1]]]},output:function(e){return e&&[e[0][0],e[1][0]]}};var p={name:"y",handles:["n","s"].map(type),input:function(e,t){return null==e?null:[[t[0][0],+e[0]],[t[1][0],+e[1]]]},output:function(e){return e&&[e[0][1],e[1][1]]}};var m={name:"xy",handles:["n","w","e","s","nw","ne","sw","se"].map(type),input:function(e){return null==e?null:number2(e)},output:function(e){return e}};var v={overlay:"crosshair",selection:"move",n:"ns-resize",e:"ew-resize",s:"ns-resize",w:"ew-resize",nw:"nwse-resize",ne:"nesw-resize",se:"nwse-resize",sw:"nesw-resize"};var y={e:"w",w:"e",nw:"ne",ne:"nw",se:"sw",sw:"se"};var w={n:"s",s:"n",nw:"sw",ne:"se",se:"ne",sw:"nw"};var g={overlay:1,selection:1,n:null,e:1,s:null,w:-1,nw:-1,ne:1,se:1,sw:-1};var _={overlay:1,selection:1,n:-1,e:null,s:1,w:null,nw:-1,ne:-1,se:1,sw:1};function type(e){return{type:e}}function defaultFilter(e){return!e.ctrlKey&&!e.button}function defaultExtent(){var e=this.ownerSVGElement||this;if(e.hasAttribute("viewBox")){e=e.viewBox.baseVal;return[[e.x,e.y],[e.x+e.width,e.y+e.height]]}return[[0,0],[e.width.baseVal.value,e.height.baseVal.value]]}function defaultTouchable(){return navigator.maxTouchPoints||"ontouchstart"in this}function local(e){while(!e.__brush)if(!(e=e.parentNode))return;return e.__brush}function empty(e){return e[0][0]===e[1][0]||e[0][1]===e[1][1]}function brushSelection(e){var t=e.__brush;return t?t.dim.output(t.selection):null}function brushX(){return brush$1(b)}function brushY(){return brush$1(p)}function brush(){return brush$1(m)}function brush$1(m){var k,x=defaultExtent,E=defaultFilter,z=defaultTouchable,A=true,T=e("start","brush","end"),K=6;function brush(e){var t=e.property("__brush",initialize).selectAll(".overlay").data([type("overlay")]);t.enter().append("rect").attr("class","overlay").attr("pointer-events","all").attr("cursor",v.overlay).merge(t).each((function(){var e=local(this).extent;u(this).attr("x",e[0][0]).attr("y",e[0][1]).attr("width",e[1][0]-e[0][0]).attr("height",e[1][1]-e[0][1])}));e.selectAll(".selection").data([type("selection")]).enter().append("rect").attr("class","selection").attr("cursor",v.selection).attr("fill","#777").attr("fill-opacity",.3).attr("stroke","#fff").attr("shape-rendering","crispEdges");var n=e.selectAll(".handle").data(m.handles,(function(e){return e.type}));n.exit().remove();n.enter().append("rect").attr("class",(function(e){return"handle handle--"+e.type})).attr("cursor",(function(e){return v[e.type]}));e.each(redraw).attr("fill","none").attr("pointer-events","all").on("mousedown.brush",started).filter(z).on("touchstart.brush",started).on("touchmove.brush",touchmoved).on("touchend.brush touchcancel.brush",touchended).style("touch-action","none").style("-webkit-tap-highlight-color","rgba(0,0,0,0)")}brush.move=function(e,t,n){e.tween?e.on("start.brush",(function(e){emitter(this,arguments).beforestart().start(e)})).on("interrupt.brush end.brush",(function(e){emitter(this,arguments).end(e)})).tween("brush",(function(){var e=this,n=e.__brush,u=emitter(e,arguments),i=n.selection,s=m.input("function"===typeof t?t.apply(this,arguments):t,n.extent),o=r(i,s);function tween(t){n.selection=1===t&&null===s?null:o(t);redraw.call(e);u.brush()}return null!==i&&null!==s?tween:tween(1)})):e.each((function(){var e=this,r=arguments,u=e.__brush,i=m.input("function"===typeof t?t.apply(e,r):t,u.extent),o=emitter(e,r).beforestart();s(e);u.selection=null===i?null:i;redraw.call(e);o.start(n).brush(n).end(n)}))};brush.clear=function(e,t){brush.move(e,null,t)};function redraw(){var e=u(this),t=local(this).selection;if(t){e.selectAll(".selection").style("display",null).attr("x",t[0][0]).attr("y",t[0][1]).attr("width",t[1][0]-t[0][0]).attr("height",t[1][1]-t[0][1]);e.selectAll(".handle").style("display",null).attr("x",(function(e){return"e"===e.type[e.type.length-1]?t[1][0]-K/2:t[0][0]-K/2})).attr("y",(function(e){return"s"===e.type[0]?t[1][1]-K/2:t[0][1]-K/2})).attr("width",(function(e){return"n"===e.type||"s"===e.type?t[1][0]-t[0][0]+K:K})).attr("height",(function(e){return"e"===e.type||"w"===e.type?t[1][1]-t[0][1]+K:K}))}else e.selectAll(".selection,.handle").style("display","none").attr("x",null).attr("y",null).attr("width",null).attr("height",null)}function emitter(e,t,n){var r=e.__brush.emitter;return!r||n&&r.clean?new Emitter(e,t,n):r}function Emitter(e,t,n){this.that=e;this.args=t;this.state=e.__brush;this.active=0;this.clean=n}Emitter.prototype={beforestart:function(){1===++this.active&&(this.state.emitter=this,this.starting=true);return this},start:function(e,t){this.starting?(this.starting=false,this.emit("start",e,t)):this.emit("brush",e);return this},brush:function(e,t){this.emit("brush",e,t);return this},end:function(e,t){0===--this.active&&(delete this.state.emitter,this.emit("end",e,t));return this},emit:function(e,t,n){var r=u(this.that).datum();T.call(e,this.that,new BrushEvent(e,{sourceEvent:t,target:brush,selection:m.output(this.state.selection),mode:n,dispatch:T}),r)}};function started(e){if((!k||e.touches)&&E.apply(this,arguments)){var r,x,z,T,K,B,P,S,V,$,C,F=this,I=e.target.__data__.type,M="selection"===(A&&e.metaKey?I="overlay":I)?o:A&&e.altKey?c:l,X=m===p?null:g[I],Y=m===b?null:_[I],j=local(F),D=j.extent,G=j.selection,N=D[0][0],O=D[0][1],q=D[1][0],H=D[1][1],J=0,L=0,Q=X&&Y&&A&&e.shiftKey,R=Array.from(e.touches||[e],(e=>{const t=e.identifier;e=i(e,F);e.point0=e.slice();e.identifier=t;return e}));s(F);var U=emitter(F,arguments,true).beforestart();if("overlay"===I){G&&(V=true);const t=[R[0],R[1]||R[0]];j.selection=G=[[r=m===p?N:d(t[0][0],t[1][0]),z=m===b?O:d(t[0][1],t[1][1])],[K=m===p?q:f(t[0][0],t[1][0]),P=m===b?H:f(t[0][1],t[1][1])]];R.length>1&&move(e)}else{r=G[0][0];z=G[0][1];K=G[1][0];P=G[1][1]}x=r;T=z;B=K;S=P;var W=u(F).attr("pointer-events","none");var Z=W.selectAll(".overlay").attr("cursor",v[I]);if(e.touches){U.moved=moved;U.ended=ended}else{var ee=u(e.view).on("mousemove.brush",moved,true).on("mouseup.brush",ended,true);A&&ee.on("keydown.brush",keydowned,true).on("keyup.brush",keyupped,true);t(e.view)}redraw.call(F);U.start(e,M.name)}function moved(e){for(const t of e.changedTouches||[e])for(const e of R)e.identifier===t.identifier&&(e.cur=i(t,F));if(Q&&!$&&!C&&1===R.length){const e=R[0];h(e.cur[0]-e[0])>h(e.cur[1]-e[1])?C=true:$=true}for(const e of R)e.cur&&(e[0]=e.cur[0],e[1]=e.cur[1]);V=true;noevent(e);move(e)}function move(e){const t=R[0],n=t.point0;var u;J=t[0]-n[0];L=t[1]-n[1];switch(M){case a:case o:X&&(J=f(N-r,d(q-K,J)),x=r+J,B=K+J);Y&&(L=f(O-z,d(H-P,L)),T=z+L,S=P+L);break;case l:if(R[1]){X&&(x=f(N,d(q,R[0][0])),B=f(N,d(q,R[1][0])),X=1);Y&&(T=f(O,d(H,R[0][1])),S=f(O,d(H,R[1][1])),Y=1)}else{X<0?(J=f(N-r,d(q-r,J)),x=r+J,B=K):X>0&&(J=f(N-K,d(q-K,J)),x=r,B=K+J);Y<0?(L=f(O-z,d(H-z,L)),T=z+L,S=P):Y>0&&(L=f(O-P,d(H-P,L)),T=z,S=P+L)}break;case c:X&&(x=f(N,d(q,r-J*X)),B=f(N,d(q,K+J*X)));Y&&(T=f(O,d(H,z-L*Y)),S=f(O,d(H,P+L*Y)));break}if(B<x){X*=-1;u=r,r=K,K=u;u=x,x=B,B=u;I in y&&Z.attr("cursor",v[I=y[I]])}if(S<T){Y*=-1;u=z,z=P,P=u;u=T,T=S,S=u;I in w&&Z.attr("cursor",v[I=w[I]])}j.selection&&(G=j.selection);$&&(x=G[0][0],B=G[1][0]);C&&(T=G[0][1],S=G[1][1]);if(G[0][0]!==x||G[0][1]!==T||G[1][0]!==B||G[1][1]!==S){j.selection=[[x,T],[B,S]];redraw.call(F);U.brush(e,M.name)}}function ended(e){nopropagation(e);if(e.touches){if(e.touches.length)return;k&&clearTimeout(k);k=setTimeout((function(){k=null}),500)}else{n(e.view,V);ee.on("keydown.brush keyup.brush mousemove.brush mouseup.brush",null)}W.attr("pointer-events","all");Z.attr("cursor",v.overlay);j.selection&&(G=j.selection);empty(G)&&(j.selection=null,redraw.call(F));U.end(e,M.name)}function keydowned(e){switch(e.keyCode){case 16:Q=X&&Y;break;case 18:if(M===l){X&&(K=B-J*X,r=x+J*X);Y&&(P=S-L*Y,z=T+L*Y);M=c;move(e)}break;case 32:if(M===l||M===c){X<0?K=B-J:X>0&&(r=x-J);Y<0?P=S-L:Y>0&&(z=T-L);M=a;Z.attr("cursor",v.selection);move(e)}break;default:return}noevent(e)}function keyupped(e){switch(e.keyCode){case 16:if(Q){$=C=Q=false;move(e)}break;case 18:if(M===c){X<0?K=B:X>0&&(r=x);Y<0?P=S:Y>0&&(z=T);M=l;move(e)}break;case 32:if(M===a){if(e.altKey){X&&(K=B-J*X,r=x+J*X);Y&&(P=S-L*Y,z=T+L*Y);M=c}else{X<0?K=B:X>0&&(r=x);Y<0?P=S:Y>0&&(z=T);M=l}Z.attr("cursor",v[I]);move(e)}break;default:return}noevent(e)}}function touchmoved(e){emitter(this,arguments).moved(e)}function touchended(e){emitter(this,arguments).ended(e)}function initialize(){var e=this.__brush||{selection:null};e.extent=number2(x.apply(this,arguments));e.dim=m;return e}brush.extent=function(e){return arguments.length?(x="function"===typeof e?e:constant(number2(e)),brush):x};brush.filter=function(e){return arguments.length?(E="function"===typeof e?e:constant(!!e),brush):E};brush.touchable=function(e){return arguments.length?(z="function"===typeof e?e:constant(!!e),brush):z};brush.handleSize=function(e){return arguments.length?(K=+e,brush):K};brush.keyModifiers=function(e){return arguments.length?(A=!!e,brush):A};brush.on=function(){var e=T.on.apply(T,arguments);return e===T?brush:e};return brush}export{brush,brushSelection,brushX,brushY};

