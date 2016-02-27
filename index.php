<!DOCTYPE html>
<html>
  <head>
    <meta  content="text/html;ISO-8859-1"  http-equiv="content-type">
    <title></title>
    <meta  name="viewport"  content="width=device-width, initial-scale=1.0">
    <link  rel="stylesheet"  href="css/leaflet.css">
    <link  rel="stylesheet"  href="css/mapas.css">
	
	<script  src="js/jquery-1.12.0.min.js"></script>
  </head>
  <body>
    <div id="map"></div>
	
	<div id="panel">
		<h1><img src="imagenes/bikeXplorer.png" /></h1>
		<div id="contenido">
			<h2>Haz click en el mapa para empezar a explorar.</h2>
			
			<div id="graficas">
				
			</div>
			
		</div>
	</div>
    
    <script  src="js/leaflet.js"></script>
	<script  src="js/Chart.min.js"></script>
    <script>		
		var map = L.map('map').setView([39.4732093,-0.3783341], 14);
		
		
		L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibGljb25vYyIsImEiOiJjaWtncnkzMW4wMDBvdzhsc2lwejg3Z3BhIn0.hCPrv82Lzr2pObLhANMexQ', {
			maxZoom: 18,
			attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
				'<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
				'Imagery © <a href="http://mapbox.com">Mapbox</a>',
			id: 'mapbox.streets'
		}).addTo(map);
		
		map._onResize();
		

		/* Click en el mapa*/
		/*var popup = L.popup();
		
		function onMapClick(e) {
			popup
				.setLatLng(e.latlng)
				.setContent("Has hecho click en las coordenadas: " + e.latlng.toString() +".")
				.openOn(map);
		}

		map.on('click', onMapClick);*/
				
		/* Poligonos */
		var poligonos = {}		
		
		 var options = {
                scaleShowGridLines: true,
                scaleGridLineColor: "rgba(80,205,255,.2)",
                scaleGridLineWidth: 1,
                scaleShowHorizontalLines: true,
                scaleShowVerticalLines: true,
                bezierCurve: true,
                bezierCurveTension: 0.4,
                pointDot: true,
                pointDotRadius: 4,
                pointDotStrokeWidth: 1,
                pointHitDetectionRadius: 20,
                datasetStroke: true,
                datasetStrokeWidth: 2,
                datasetFill: true,
              };
			  
		
	
		
		$(function() {			
		
			
			/* Interacción con los polígonos */	
			$.getJSON( "datos/grid.geojson", function( data ) {
				var i=0;
			  $.each( data["features"], function( key, val ) {	
					/* En key esta el id del cuadrado, en data["features"][key]["geometry"]["coordinates"] las coordenadas */	
					var coordenadas = data["features"][key]["geometry"]["coordinates"][0];
					var nombre=	"poligono_"+i		
					poligonos.nombre =  L.polygon([
						[coordenadas[0][1],coordenadas[0][0]],
						[coordenadas[1][1],coordenadas[1][0]],
						[coordenadas[2][1],coordenadas[2][0]],
						[coordenadas[3][1],coordenadas[3][0]],
						[coordenadas[4][1],coordenadas[4][0]]
						], {
							stroke: true,
							color: '#fff',
							opacity: 0.005,
							fill: true,
							fillColor: '#fff',
							fillOpacity: 0.1,
							className: nombre
					});	

					poligonos.nombre.addTo(map);
					poligonos.nombre.on('click', function(e) {
						
						$("#graficas").empty();
						$("#contenido h2").html("Coordenadas: "+e.latlng.toString()+" (Cuadrante "+nombre.split("_")[1]+")");
						var dias = []; var horas = []; 
						var data_dias = []; var data_martes = []; 
						var context_dias = ""; var context_horas = "";
						var myNewChart_dias = "";var myNewChart_horas = "";
							
						
						$.getJSON( "datos/"+nombre.split("_")[1]+"_pred_horas.json", function( data ) {
							
							$.each( data, function( key, val ) {
								horas[val["hora"]]=val["pred"]
								
							});
							
							/* Lunes */
							data_horas = {
							labels: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],
								datasets: [{
								  label: "Media horaria",
								  fillColor: "rgba(151,187,205,0.2)",
								  strokeColor: "rgba(151,187,205,1)",
								  pointColor: "rgba(151,187,205,1)",
								  pointStrokeColor: "#fff",
								  pointHighlightFill: "#fff",
								  pointHighlightStroke: "rgba(151,187,205,1)",
								  data: [horas[0],horas[1],horas[2],horas[3],horas[4],horas[5],horas[6],horas[7],horas[8],horas[9],horas[10],horas[11],horas[12],horas[13],horas[14],horas[15],horas[16],horas[17],horas[18],horas[19],horas[20],horas[21],horas[22],horas[23]]
								}]
						  };
						  
						  $("#graficas").append('<div><div id="div_horas">Media horaria prevista</div>'+
												  '<canvas class="grafica" id="grafica_horas"></canvas class="grafica"></div>');
							
						  
						   context_horas = document.getElementById("grafica_horas").getContext("2d");
						   myNewChart_horas = new Chart(context_horas).Line(data_horas, options);
						   
							  
							});
					   
						});
						i++;
					});			  
				});	


			/* Estaciones */
			var estaciones = {}	
			var punto = L.Icon.extend({
				options: {
					iconSize:     [10, 10]
				}
			});
			
			var icono_1 = new punto({iconUrl: 'imagenes/verde.png'});
			var icono_2 = new punto({iconUrl: 'imagenes/amarillo.png'});
			var icono_3 = new punto({iconUrl: 'imagenes/rojo.png'});		

			var estaciones_color=[0,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,3,1,2,1,2,1,2,1,2,1,1,3,1,1,2,2,3,3,1,1,3,1,2,3,3,3,1,3,2,3,3,3,3,2,3,3,3,2,3,3,3,3,2,2,3,3,3,3,3,1,3,3,3,3,3,3,3,3,3,1,1,3,1,3,1,3,1,1,1,1,3,3,3,3,1,3,3,3,3,3,3,3,3,2,1,1,2,3,2,1,1,1,1,1,1,3,2,1,3,3,3,2,2,3,2,2,3,1,2,3,1,1,3,2,1,2,1,1,2,3,2,1,1,2,1,1,1,,3,3,3,3,3,3,1,1,1,3,3,3,3,3,2,3,3,3,3,3,3,3,3,1,1,2,3,1,2,3,3,2,1,2,3,2,3,2,3,1,1,3,3,3,3,1,2,2,1,1,1,2,2,1,1,2,2,1,1,3,3,1,1,3,1,1,1,1,1,2,1,2,1,2,2,1,1,1,1,1,1,2,2,2,3,3,3,2,1,1,1,1,1,1,3,2,1,1,1,1,2,1,2,1,1,3,2,3,2,3,2,1,3,2,2,1,1,1,1,1,2,1,1,3,3,3,3,3]
			  
		
		
			
			<?php
			$fila = 1;
			if (($gestor = fopen("datos/estaciones_valenbisi.csv", "r")) !== FALSE) {
				while (($datos = fgetcsv($gestor, ",")) !== FALSE) {
					$numero = count($datos);
					
					$fila++;
					if($fila>2){
						$id_estacion="estacion_".$datos[1];
						$longitud=$datos[2];
						$latitud=$datos[3];					
						?>
						if(estaciones_color[<?=$datos[1]?>]==1) {estaciones.<?=$id_estacion?> =  L.marker([<?=$latitud?>, <?=$longitud?>], {icon: icono_1});}
						else if(estaciones_color[<?=$datos[1]?>]==2) {estaciones.<?=$id_estacion?> =  L.marker([<?=$latitud?>, <?=$longitud?>], {icon: icono_2});}
						else {estaciones.<?=$id_estacion?> =  L.marker([<?=$latitud?>, <?=$longitud?>], {icon: icono_3});}
						
						
						estaciones.<?=$id_estacion?>.addTo(map);
						estaciones.<?=$id_estacion?>.on('click', function(e) {
							$("#graficas").empty();
							$("#contenido h2").html("Estaci&oacute;n ID: <?=$datos[1]?>");
							var horas=[]; var horas_pred=[]; var lunes = []; var martes = []; var miercoles = []; var jueves = []; var viernes = []; var sabado = []; var domingo = [];
							var data_lunes = []; var data_martes = []; var data_miercoles = []; var data_jueves = []; var data_viernes = []; var data_sabado = []; var data_domingo = [];
							var context_domingo = ""; var context_lunes = "";var context_martes = "";var context_miercoles = "";var context_jueves = "";var context_viernes = "";var context_sabado = "";
							var myNewChart_domingo = "";var myNewChart_lunes = "";var myNewChart_martes = "";var myNewChart_miercoles = "";var myNewChart_jueves = "";var myNewChart_viernes = "";var myNewChart_sabado = "";
								
							$.getJSON( "datos/"+<?=$datos[1]?>+"_pred.json", function( data ) {
							
							$.each( data, function( key, val ) {
								horas.push(val["hour"]);
								horas_pred.push(val["pred"]);
							});
							
							/* Lunes */
							data_horas = {
							labels: horas,
								datasets: [{
								  label: "Media horaria",
								  fillColor: "rgba(151,187,205,0.2)",
								  strokeColor: "rgba(151,187,205,1)",
								  pointColor: "rgba(151,187,205,1)",
								  pointStrokeColor: "#fff",
								  pointHighlightFill: "#fff",
								  pointHighlightStroke: "rgba(151,187,205,1)",
								  data: horas_pred
								}]
						  };
						  
						  $("#graficas").append('<div><div id="div_horas">Media horaria prevista</div>'+
												  '<canvas class="grafica" id="grafica_horas"></canvas class="grafica"></div>');
							
						  
						   context_horas = document.getElementById("grafica_horas").getContext("2d");
						   myNewChart_horas = new Chart(context_horas).Line(data_horas, options);
						   
							  
							});
							
							
							$.getJSON( "datos/"+<?=$datos[1]?>+"_resumen.json", function( data ) {
								
								$.each( data, function( key, val ) {
									switch(val["wday"]){
										case 1:
											domingo[val["hora"]]=Math.round(val["media"]);
										break;
										
										case 2:
											lunes[val["hora"]]=Math.round(val["media"]);
										break;
										
										case 3:
											martes[val["hora"]]=Math.round(val["media"]);
										break;
										
										case 4:
											miercoles[val["hora"]]=Math.round(val["media"]);
										break;
										
										case 5:
											jueves[val["hora"]]=Math.round(val["media"]);
										break;
										
										case 6:
											viernes[val["hora"]]=Math.round(val["media"]);
										break;
										
										case 7:
											sabado[val["hora"]]=Math.round(val["media"]);
										break;
									}
									
								});
								
								/* Lunes */
								data_lunes = {
								labels: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],
								datasets: [{
								  label: "Media horaria",
								  fillColor: "rgba(151,187,205,0.2)",
								  strokeColor: "rgba(151,187,205,1)",
								  pointColor: "rgba(151,187,205,1)",
								  pointStrokeColor: "#fff",
								  pointHighlightFill: "#fff",
								  pointHighlightStroke: "rgba(151,187,205,1)",
								  data: [lunes[0],lunes[1],lunes[2],lunes[3],lunes[4],lunes[5],lunes[6],lunes[7],lunes[8],lunes[9],lunes[10],lunes[11],lunes[12],lunes[13],lunes[14],lunes[15],lunes[16],lunes[17],lunes[18],lunes[19],lunes[20],lunes[21],lunes[22],lunes[23]]
								}]
							  };
							  
							  $("#graficas").append('<div><div id="div_lunes">Media horaria: Lunes</div>'+
													  '<canvas class="grafica" id="grafica_lunes"></canvas class="grafica"></div>');
								
							  
							   context_lunes = document.getElementById("grafica_lunes").getContext("2d");
							   myNewChart_lunes = new Chart(context_lunes).Line(data_lunes, options);
							   
							   /* Martes */
							   data_martes = {
								labels: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],
								datasets: [{
								  label: "Media horaria",
								  fillColor: "rgba(151,187,205,0.2)",
								  strokeColor: "rgba(151,187,205,1)",
								  pointColor: "rgba(151,187,205,1)",
								  pointStrokeColor: "#fff",
								  pointHighlightFill: "#fff",
								  pointHighlightStroke: "rgba(151,187,205,1)",
								  data: [martes[0],martes[1],martes[2],martes[3],martes[4],martes[5],martes[6],martes[7],martes[8],martes[9],martes[10],martes[11],martes[12],martes[13],martes[14],martes[15],martes[16],martes[17],martes[18],martes[19],martes[20],martes[21],martes[22],martes[23]]
								}]
							  };
							  
							  $("#graficas").append('<div><div id="div_martes">Media horaria: martes</div>'+
													  '<canvas class="grafica" id="grafica_martes"></canvas class="grafica"></div>');
								
							  
							   context_martes = document.getElementById("grafica_martes").getContext("2d");
							   myNewChart_martes = new Chart(context_martes).Line(data_martes, options);
							   
							   /* Miercoles */
							   data_miercoles = {
								labels: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],
								datasets: [{
								  label: "Media horaria",
								  fillColor: "rgba(151,187,205,0.2)",
								  strokeColor: "rgba(151,187,205,1)",
								  pointColor: "rgba(151,187,205,1)",
								  pointStrokeColor: "#fff",
								  pointHighlightFill: "#fff",
								  pointHighlightStroke: "rgba(151,187,205,1)",
								  data: [miercoles[0],miercoles[1],miercoles[2],miercoles[3],miercoles[4],miercoles[5],miercoles[6],miercoles[7],miercoles[8],miercoles[9],miercoles[10],miercoles[11],miercoles[12],miercoles[13],miercoles[14],miercoles[15],miercoles[16],miercoles[17],miercoles[18],miercoles[19],miercoles[20],miercoles[21],miercoles[22],miercoles[23]]
								}]
							  };
							  
							  $("#graficas").append('<div><div id="div_miercoles">Media horaria: miercoles</div>'+
													  '<canvas class="grafica" id="grafica_miercoles"></canvas class="grafica"></div>');
								
							  
							   context_miercoles = document.getElementById("grafica_miercoles").getContext("2d");
							   myNewChart_miercoles = new Chart(context_miercoles).Line(data_miercoles, options);
							   
							   
							   /* Jueves */
							   data_jueves = {
								labels: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],
								datasets: [{
								  label: "Media horaria",
								  fillColor: "rgba(151,187,205,0.2)",
								  strokeColor: "rgba(151,187,205,1)",
								  pointColor: "rgba(151,187,205,1)",
								  pointStrokeColor: "#fff",
								  pointHighlightFill: "#fff",
								  pointHighlightStroke: "rgba(151,187,205,1)",
								  data: [jueves[0],jueves[1],jueves[2],jueves[3],jueves[4],jueves[5],jueves[6],jueves[7],jueves[8],jueves[9],jueves[10],jueves[11],jueves[12],jueves[13],jueves[14],jueves[15],jueves[16],jueves[17],jueves[18],jueves[19],jueves[20],jueves[21],jueves[22],jueves[23]]
								}]
							  };
							  
							  $("#graficas").append('<div><div id="div_jueves">Media horaria: jueves</div>'+
													  '<canvas class="grafica" id="grafica_jueves"></canvas class="grafica"></div>');
								
							  
							   context_jueves = document.getElementById("grafica_jueves").getContext("2d");
							   myNewChart_jueves = new Chart(context_jueves).Line(data_jueves, options);
							   
							    /* Viernes */
							   data_viernes = {
								labels: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],
								datasets: [{
								  label: "Media horaria",
								  fillColor: "rgba(151,187,205,0.2)",
								  strokeColor: "rgba(151,187,205,1)",
								  pointColor: "rgba(151,187,205,1)",
								  pointStrokeColor: "#fff",
								  pointHighlightFill: "#fff",
								  pointHighlightStroke: "rgba(151,187,205,1)",
								  data: [viernes[0],viernes[1],viernes[2],viernes[3],viernes[4],viernes[5],viernes[6],viernes[7],viernes[8],viernes[9],viernes[10],viernes[11],viernes[12],viernes[13],viernes[14],viernes[15],viernes[16],viernes[17],viernes[18],viernes[19],viernes[20],viernes[21],viernes[22],viernes[23]]
								}]
							  };
							  
							  $("#graficas").append('<div><div id="div_viernes">Media horaria: viernes</div>'+
													  '<canvas class="grafica" id="grafica_viernes"></canvas class="grafica"></div>');
								
							  
							   context_viernes = document.getElementById("grafica_viernes").getContext("2d");
							   myNewChart_viernes = new Chart(context_viernes).Line(data_viernes, options);
							   
							    /* sabado */
							   data_sabado = {
								labels: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],
								datasets: [{
								  label: "Media horaria",
								  fillColor: "rgba(151,187,205,0.2)",
								  strokeColor: "rgba(151,187,205,1)",
								  pointColor: "rgba(151,187,205,1)",
								  pointStrokeColor: "#fff",
								  pointHighlightFill: "#fff",
								  pointHighlightStroke: "rgba(151,187,205,1)",
								  data: [sabado[0],sabado[1],sabado[2],sabado[3],sabado[4],sabado[5],sabado[6],sabado[7],sabado[8],sabado[9],sabado[10],sabado[11],sabado[12],sabado[13],sabado[14],sabado[15],sabado[16],sabado[17],sabado[18],sabado[19],sabado[20],sabado[21],sabado[22],sabado[23]]
								}]
							  };
							  
							  $("#graficas").append('<div><div id="div_sabado">Media horaria: sabado</div>'+
													  '<canvas class="grafica" id="grafica_sabado"></canvas class="grafica"></div>');
								
							  
							   context_sabado = document.getElementById("grafica_sabado").getContext("2d");
							   myNewChart_sabado = new Chart(context_sabado).Line(data_sabado, options);
							   
							    /* Domingo */
							   data_domingo = {
								labels: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],
								datasets: [{
								  label: "Media horaria",
								  fillColor: "rgba(151,187,205,0.2)",
								  strokeColor: "rgba(151,187,205,1)",
								  pointColor: "rgba(151,187,205,1)",
								  pointStrokeColor: "#fff",
								  pointHighlightFill: "#fff",
								  pointHighlightStroke: "rgba(151,187,205,1)",
								  data: [domingo[0],domingo[1],domingo[2],domingo[3],domingo[4],domingo[5],domingo[6],domingo[7],domingo[8],domingo[9],domingo[10],domingo[11],domingo[12],domingo[13],domingo[14],domingo[15],domingo[16],domingo[17],domingo[18],domingo[19],domingo[20],domingo[21],domingo[22],domingo[23]]
								}]
							  };
							  
							  $("#graficas").append('<div><div id="div_domingo">Media horaria: domingo</div>'+
													  '<canvas class="grafica" id="grafica_domingo"></canvas class="grafica"></div>');
								
							  
							   context_domingo = document.getElementById("grafica_domingo").getContext("2d");
							   myNewChart_domingo = new Chart(context_domingo).Line(data_domingo, options);
							  
							});

						});
						<?php
					}
				}
				fclose($gestor);
			}
			?>	
		});
		
		
		
		
	</script>
	
			
	


  </body>
</html>
