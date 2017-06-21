<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
	pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>File Upload</title>
</head>
<body>
	<center>
		<h1>File Upload</h1>
		<form id="inputForm" method="post" action=""
			enctype="multipart/form-data">
			Select file to upload: <input type="file" id="files" name="files[]"
				multiple />
			<output id="list"></output>

			<div id="fileUploadView"></div>
		</form>
		<script>
			var tableDetails = [];
			function handleFileSelect(evt) {
				var files = evt.target.files; // FileList object

				// files is a FileList of File objects. List some properties.
				var output = [];
				for (var i = 0, cf; cf = files[i]; i++) {
					var thisfile = {
						fileName : cf.name,
						status : 'queued',
						file : cf
					};
					tableDetails.push(thisfile);
				}
				displayArray();
				for (x in tableDetails) {
					var filename = tableDetails[x].fileName;
					loadFile(filename, x, tableDetails[x].file);
				}
			}
			document.getElementById('files').addEventListener('change',
					handleFileSelect, false);
			var loadcount = 0;

			function loadFile(filename, srl, file) {
				var fileInfo = JSON.parse(getFileInfo(filename));
				if (fileInfo.length == 0) {
					/*
					document.getElementById('myFileId').value = filename;
					document.getElementById('myForm').submit();
					 */
					var stop = file.size;
					var totalSize = Math.floor(file.size / 1000000) + 1;
					var reader = new FileReader();
					var start = 0;
					console.log('file size=' + file.size);
					reader.onload = function(evt) {
						console.log('starting reading');
						tableDetails[srl].status = '<pre>Loading'
								+ " ".repeat(totalSize) + "|</pre>";
						displayArray();
						var i = 0;
						for (i = 0, start = 0; start < stop; i++, start += 1000000) {
							loadFileChunk(filename, i, srl, evt, start, stop, totalSize, loadcount);								
						}
					};
					// var blob = file.slice(start, stop + 1);
					reader.readAsArrayBuffer(file);
					console.log('reader call complete');

					// reader.readAsBinaryString(file.slice(start, stop + 1));

					/*
					 var xhr = new XMLHttpRequest();
					 xhr.open('post', '/FileUpload/folderUploadServlet?call=saveFile&file='+filename, false);
					 xhr.setRequestHeader("Cache-Control", "no-cache");
					 xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
					 xhr.setRequestHeader ("ENCTYPE", "multipart/form-data");
					 // xhr.setRequestHeader("Content-Type", "multipart/form-data");
					    xhr.setRequestHeader("X-File-Name", file.fileName);
					    xhr.setRequestHeader("X-File-Size", file.fileSize);
					    xhr.setRequestHeader("X-File-Type", file.type);
					var formData = new FormData();
					formData.append(filename, file);
					xhr.send(formData);
					 */

				} else {
					tableDetails[srl].status = 'Loaded';
				}
				displayArray();
			}

			function loadFileChunk(filename, chunkSrl, uiSrl, evt, startByte, stopByte, totalSize, loadCount) {
				var fileInfo = JSON.parse(getFileSrlInfo(filename, chunkSrl));
				if (fileInfo.length != 0) {
					tableDetails[uiSrl].status = tableDetails[uiSrl].status
							.substring(0, chunkSrl + 12)
							+ '.'
							+ tableDetails[uiSrl].status
									.substring(chunkSrl + 13);
					displayArray();
					return;
				}
				loadcount++;
				setTimeout(function(){
						try {
							console.log('stating loading i=' + chunkSrl + ',start='
									+ startByte);
							var xhr = new XMLHttpRequest();

							var endByte = (stopByte - startByte > 1000000 ? 1000000 : stopByte
									- startByte);
							xhr.open('POST',
									'/FileUpload/folderUploadServlet?call=saveFile&file='
											+ filename + '&size=' + endByte
											+ '&totalSize=' + totalSize + '&srl='
											+ chunkSrl, false);
							xhr.setRequestHeader('Content-Type',
									'application/octet-stream');
							var arrayBuffer = evt.target.result;
							var dataView = new DataView(arrayBuffer, startByte, endByte,
									arrayBuffer.byteLength);

							// var byte = dataView.getUint8(0);   //gets first byte of ArrayBuffer
							xhr.send(dataView);
						} catch (err) {
							console.log(err.message);
						}
						tableDetails[uiSrl].status = tableDetails[uiSrl].status
								.substring(0, chunkSrl + 12)
								+ '.'
								+ tableDetails[uiSrl].status.substring(chunkSrl + 13);
						displayArray();
						console.log('loading complete i=' + chunkSrl);

						if (chunkSrl == totalSize-1) {
							tableDetails[uiSrl].status = 'Loaded';
							displayArray();							
						}
					
				}, loadCount * 2000);
			}

			function getFileInfo(filename) {
				var xmlhttp = new XMLHttpRequest();
				var url = "/FileUpload/folderUploadServlet?call=listFiles&filename="
						+ filename;

				xmlhttp.open("GET", url, false);
				xmlhttp.send();
				var myArr = xmlhttp.responseText;
				return myArr;
			}

			function getFileSrlInfo(filename, srl) {
				var xmlhttp = new XMLHttpRequest();
				var url = "/FileUpload/folderUploadServlet?call=listFileSrl&filename="
						+ filename + '&srl=' + srl;

				xmlhttp.open("GET", url, false);
				xmlhttp.send();
				var myArr = xmlhttp.responseText;
				return myArr;
			}

			function displayArray() {
				var output = [];
				for (x in tableDetails) {
					/*
					var bgcolor = (tableDetails[x].status == 'queued' ? '#0000FF'
							: (tableDetails[x].status == 'Loaded' ? '#00FF00'
									: '#FF0000'));
					console.log(bgcolor);
					*/
					var bgcolor = "#FFFFFF";
					output.push('<tr><td>' + tableDetails[x].fileName + '</td>'
							+ '<td width="400" bgcolor="' + bgcolor
							+ '">'
							+ tableDetails[x].status + '</td></tr>');
				}
				document.getElementById('fileUploadView').innerHTML = '<table width="400" border="1">'
						+ output.join('') + '</table>';
			}
		</script>

	</center>
</body>
</html>