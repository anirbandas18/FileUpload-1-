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
		<form method="post" action="" enctype="multipart/form-data">
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
						var f = cf;
						loadFile(f, i, output);
					}

				}

				function loadFile(f, i, output) {
					setTimeout(() => {
						
					output.push('<li><strong>', escape(f.name), '</strong> (',
							f.type || 'n/a', ') - ', f.size,
							' bytes, last modified: ',
							f.lastModifiedDate ? f.lastModifiedDate
									.toLocaleDateString() : 'n/a', f.name,
							'</li>');
					document.getElementById('list').innerHTML = '<ul>'
							+ output.join('') + '</ul>';
					var filesize = f.size;
					var chunk = 1000002;
					var totalSize = Math.floor(f.size / chunk) + 1;

					var rows = Math.floor(totalSize / 100);
					var tableHtml = [];

					// console.log('total number of rows=' + rows);
					/*
					for (var rowSrl=0; rowSrl<=rows; rowSrl++) {
						for (var colSrl=0; colSrl<100; colSrl++) {
							// console.log('init for row/col= ' + rowSrl + ',' + colSrl);		
							tableDetails[rowSrl][colSrl]='<td>&nbsp;</td>';	    		
						}
					}
					 */
					for (var cellSrl = 0; cellSrl <= totalSize; cellSrl++) {
						tableDetails.push('<td>&nbsp;</td>');
					}

					var resourceCount = 0;
					var filelist = JSON.parse(getFileList(f.name, totalSize));
					for (i = 0; i < filelist.length; i++) {
						var srl1 = filelist[i].Filename;
						tableDetails[srl1] = '<td bgcolor=black>&nbsp;</td>';						
					}
					displayArray();
					console.log(filelist);
					setTimeout(function() {
					for (var offset = 0, srl = 0; offset < filesize; offset += chunk, srl++) {
						readFile(f, srl, totalSize, offset, chunk);
					}}, 1000);
					}, (i+1)*1000);
				}

				function getServerStat(filename, totalSize) {
					var xmlhttp = new XMLHttpRequest();
					var url = "/FileUpload/fileUploadServlet?call=findStatus&filename="
							+ filename + '&totalFiles=' + totalSize;

					xmlhttp.open("GET", url, false);
					xmlhttp.send();
					var myArr = xmlhttp.responseText;
					return myArr;
				}

				function getFileList(filename, totalSize) {
					var xmlhttp = new XMLHttpRequest();
					var url = "/FileUpload/fileUploadServlet?call=listFiles&filename="
							+ filename + '&totalFiles=' + totalSize;

					xmlhttp.open("GET", url, false);
					xmlhttp.send();
					var myArr = xmlhttp.responseText;
					return myArr;
				}

				function getFileInfo(filename, srl, totalFiles) {
					var xmlhttp = new XMLHttpRequest();
					var url = "/FileUpload/fileUploadServlet?call=fileInfo&filename="
							+ filename + '&srl=' + srl + "&totalFiles=" + totalFiles;

					xmlhttp.open("GET", url, false);
					xmlhttp.send();
					var myArr = xmlhttp.responseText;
					return myArr;
				}

				function displayArray() {
					var output = [];
					for (x in tableDetails) {
						if (x%100 == 0 && x !== 0) {
							output.push('</tr><tr>');
						}
						output.push(tableDetails[x]);
					}
					output.push('</tr>');
					document.getElementById('fileUploadView').innerHTML = '<table border="1">'
							+ output.join('') + '</table>';
				}
				var loadSrl = 0;
				function readFile(f1, srl1, totalSize1, offset1, chunk1) {

					console.log('loading after a delay of ' + loadSrl + "sec.");
					setTimeout(function() {
						var fileInfo = JSON.parse(getFileInfo(f1.name, srl1, totalSize1));
						if (fileInfo.length == 0) {
							loadSrl++;
							var reader2 = new FileReader();
							reader2.onload = function(e) {
							var bytes = new Uint8Array(e.target.result.length);
							for (var i=0; i<e.target.result.length; i++)
								bytes[i] = e.target.result.charCodeAt(i);
							tableDetails[srl1] = '<td bgcolor=blue>&nbsp;</td>';
							// displayArray();
							var xhr = new XMLHttpRequest();
							xhr.onreadystatechange = function() {
							    if (this.readyState == 4 && this.status == 200) {
									tableDetails[srl1] = '<td bgcolor=black>&nbsp;</td>';						
									displayArray();
							    }
							};							// Create a new XMLHttpRequest
							var url1 = [];
							url1.push('/FileUpload/fileUploadServlet');
							url1.push('?filename='+f1.name);
							url1.push('&srl='+srl1);
							url1.push('&totalFiles='+totalSize1);
							url1.push('&call=saveFile&size=');
							url1.push(e.target.result.length);
							url1.push('&data=');
							// url.push(e.target.result);
							xhr.open("POST", url1.join(""), false);
							/*
							xhr.setRequestHeader("Content-type",
									"multipart/form-data");
							var formData = new FormData();
							formData.append('call', 'saveFile');
							formData.append('totalFiles', totalSize1);
							formData.append('filename', f1.name);
							formData.append('srl', srl1);
							formData.append('bindata', 'a'); // e.target.result);
							  formData.append('key2', 'value2');							
							formdata.push('call=saveFile&totalFiles=' + totalSize1
									+ '&filename=');
							  formData.push(f1.name);
							  formData.push('&srl=');
							  formData.push(srl1);
							  formData.push('&data=');
							  formData.push(e.target.result); // e.target.result);
							*/
							xhr.send(bytes);
						}
						// console.log('srl=' + srl1 + ' of ' + totalSize1);
						// console.log('offset=' + offset1);
						var blob = f1.slice(offset1, offset1 + chunk1,  "{type: 'text/plain'}"); // "{type: 'application/octet-binary'}");
						reader2.readAsBinaryString(blob);
						}
						//	var fr = new FileReader();

						//xhr.send();	    // e.target.result should contain the text
						// console.log(e.target.result);		
						//	};
						//	fr.readAsText(blob);
						
					}, loadSrl * 100);
				}

				  
				function displayLine(blob) {
				}
				document.getElementById('files').addEventListener('change',
						handleFileSelect, false);
				/*
				function uploadFile() {

				    var xhr = new XMLHttpRequest;

				    xhr.open("POST", "/fileUploadServlet, true);
				    xhr.onreadystatechange = function() {
				        if (xhr.readyState === 4) {
				            alert(xhr.responseText);
				        }
				    };
				    var contentType = "multipart/form-data; boundary=" + boundary;
				    xhr.setRequestHeader("Content-Type", contentType);

				    for (var header in this.headers) {
				        xhr.setRequestHeader(header, headers[header]);
				    }

				    // here's our data variable that we talked about earlier
				    var data = this.buildMessage(this.elements, boundary);

				    // finally send the request as binary data
				    xhr.sendAsBinary(data);
				}
				 */
			</script>

	</center>
</body>
</html>