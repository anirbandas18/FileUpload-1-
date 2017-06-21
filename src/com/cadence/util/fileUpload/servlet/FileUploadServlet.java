package com.cadence.util.fileUpload.servlet;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

/**
 * Servlet implementation class SearchServlet
 */
public class FileUploadServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	// private static final String appPath = "/software/cdpapp/upload";
	public static final String appPath = "C:/Uploads/uploadFiles";
	public static final String workPath = appPath + "/work";

	private static Map<String, String> fileUploadStatus = new HashMap<>();

	public void init(ServletConfig config) throws ServletException {
		super.init(config);
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		// TODO Auto-generated method stub

		doPost(request, response);
	}

	private String message;

	/**
	 * handles file upload
	 */
	/*
	@PostMapping(value = "/compressUrl")
    public @ResponseBody DeferredResult<String> compress(@RequestBody FileOperationRequest request,
                    HttpServletResponse response) throws IOException {

	*/
	
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		// gets absolute path of the web application
		// String appPath = request.getServletContext().getRealPath("");
		// System.out.println(appPath);
		for (Enumeration<String> e = request.getParameterNames(); e.hasMoreElements();) {
			String parameter = (String) e.nextElement();
			if (!"data".equals(parameter)) {
				System.out.println("name=" + parameter + ";value=" + request.getParameter(parameter));
			}
		}
		if ("listFiles".equals(request.getParameter("call"))) {
			listFiles(request, response);
		} else if ("fileInfo".equals(request.getParameter("call"))) {
			listFiles(request, response, (String) request.getParameter("srl"));
		} else if ("findStatus".equals(request.getParameter("call"))) {
			findStatus(request, response, (String) request.getParameter("srl"));
		} else if ("saveFile".equals(request.getParameter("call"))) {
			saveFile(request);
		}

	}

	private void saveFile(HttpServletRequest request) throws IOException, ServletException {
		// constructs path of the directory to save uploaded file

		String filename = request.getParameter("filename");
		int totalFiles = Integer.parseInt(request.getParameter("totalFiles"));
		int size = Integer.parseInt(request.getParameter("size"));
		File dir = createDir(filename);

		String srl = request.getParameter("srl");
		// Create path components to save the file
		final String path = request.getParameter("destination");
		// final Part filePart = request.getPart("file");
		// final String fileName = getFileName(filePart);

		String data = getBody(request, dir, srl, totalFiles, filename, size);
		int i = 1;

		File[] files = dir.listFiles();
		if (files.length == totalFiles) {
			System.out.println("Received final file");
			mergeFiles(dir.getAbsolutePath(), appPath, filename, totalFiles);
			// merge files
		}

	}

	public static String getBody(HttpServletRequest request, File dir, String writeTofile, int totalFiles,
			String filename, int size) throws IOException {

		String body = null;
		StringBuilder stringBuilder = new StringBuilder();
		BufferedReader bufferedReader = null;

		OutputStream out = null;

		InputStream filecontent = null;
		try {
			filecontent = request.getInputStream();

			int read = 0;
			byte[] bytes = IOUtils.toByteArray(filecontent, size);
			System.out.println("size=" + bytes.length);
			File fileName = new File(dir, writeTofile);
			FileUtils.writeByteArrayToFile(fileName, bytes);

			System.out.println("New file " + filename + " created at " + appPath + ",size=" + bytes.length);
		} catch (FileNotFoundException fne) {
			System.out.println("You either did not specify a file to upload or are "
					+ "trying to upload a file to a protected or nonexistent " + "location.");
			System.out.println("<br/> ERROR: " + fne.getMessage());

		} finally {
			if (out != null) {
				out.close();
			}
			if (filecontent != null) {
				filecontent.close();
			}
		}


		// File fileName = new File(dir, writeTofile);
		// FileUtils.writeByteArrayToFile(fileName, buffer);
		// body = stringBuilder.toString();
		return body;
	}

	private synchronized void mergeFiles(String inputDir, String outputDir, String outputFileName, long noOfFiles)
			throws IOException {

		File outputfile = null;
		outputfile = new File(outputDir + "/" + outputFileName);
		if (outputfile.exists()) {
			return;
		}

		FileUtils.forceMkdir(outputfile.getParentFile());

		for (long i = 0; i < noOfFiles; i++) {
			FileOutputStream fstream = null;
			FileInputStream fis;
			try {
				fstream = new FileOutputStream(outputfile, true);
				byte[] buffer = new byte[1024];
				fis = new FileInputStream(inputDir + "/" + i);

				int noOfBytes;
				while ((noOfBytes = fis.read(buffer)) != -1) {
					fstream.write(buffer, 0, noOfBytes);
				}

				fis.close();
				fstream.flush();
				fstream.close();

			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	private File createDir(String filename) throws IOException {
		File dir = new File(workPath, filename);
		/*
		 * if (dir.exists() && !dir.isDirectory()) { FileUtils.forceDelete(dir);
		 * }
		 */
		FileUtils.forceMkdir(dir);
		return dir;
	}

	/**
	 * Extracts file name from HTTP header content-disposition
	 */
	private String extractFileName(Part part) {
		String contentDisp = part.getHeader("content-disposition");
		String[] items = contentDisp.split(";");
		for (String s : items) {
			if (s.trim().startsWith("filename")) {
				return s.substring(s.indexOf("=") + 2, s.length() - 1);
			}
		}
		return "";
	}

	private void listFiles(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		fileUploadStatus.clear();
		listFiles(request, response, "");
	}

	private void listFiles(HttpServletRequest request, HttpServletResponse response, String srl)
			throws ServletException, IOException {
		// TODO Auto-generated method stub
		String filename = request.getParameter("filename");
		Long lastModifiedDate = null;
		boolean clientModifiedDateCheck = true;
		try {
			lastModifiedDate = Long.parseLong(request.getParameter("lastModified"));
		} catch (NumberFormatException e) {
			clientModifiedDateCheck = false;
		}
		File outputfile = null;
		outputfile = new File(appPath + "/" + filename);
		File outputWorkingDir = null;
		outputWorkingDir = new File(workPath + "/" + filename);
		if (clientModifiedDateCheck && outputfile.exists() && outputfile.lastModified() < lastModifiedDate) {
			FileUtils.deleteQuietly(outputfile);
		}

		if (clientModifiedDateCheck && outputWorkingDir.exists() && outputWorkingDir.lastModified() < lastModifiedDate) {
			FileUtils.deleteQuietly(outputWorkingDir);			
		}
		
		File dir = createDir(filename);
		// int totalFiles =
		// Integer.parseInt(request.getParameter("totalFiles"));
		String str;

		String jsonContent = "{\n";

		PrintWriter out = response.getWriter();

		// String[] files = dir.list();
		File[] files = dir.listFiles();
		JSONArray arr = new JSONArray();

		jsonContent += "\"files\":\t\n";

		for (File aFile : files) {
			if (StringUtils.isEmpty(srl) || aFile.getName().equals(srl)) {
				str = aFile.getName();
				JSONObject obj = new JSONObject();
				obj.put("Filename", aFile.getName());
				obj.put("size", aFile.length());
				arr.add(obj);
			}
		}

		System.out.println(arr.toString());
		// out.print(jsonContent);
		out.flush();

		response.setContentType("text/plain");
		response.setCharacterEncoding("UTF-8");
		response.getWriter().write(arr.toString());
	}

	private void findStatus(HttpServletRequest request, HttpServletResponse response, String srl)
			throws ServletException, IOException {

		String jsonContent = "{\n";

		// String[] files = dir.list();
		JSONArray arr = new JSONArray();

		jsonContent += "\"files\":\t[\n";

		for (Object key : fileUploadStatus.keySet()) {
			JSONObject obj = new JSONObject();
			obj.put("Filename", key);
			arr.add(obj);
		}

		response.setContentType("text/json");
		response.setCharacterEncoding("UTF-8");
		response.getWriter().write(arr.toString());
	}
}
