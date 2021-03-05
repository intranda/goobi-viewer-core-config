/**
* Watch the messages_*.properties files in the project. On change, copy them to /opt/digiverso/viewer/config, overwriting the local messages files
* Only the local messages files are watched for changes, so to enable continuous messages updates they need to be overwritten.
* TODO: Maybe update ViewerResourceBundle to also watch global messages files. But that would only make sense for development systems
*/

const fs = require("fs")
const XML = require('pixl-xml');
const process = require('process');

//not used because messages are written to config dir
function getTomcatDir() {
	let homedir = require("os").homedir();
	let rawdata = fs.readFileSync(homedir + '/.config/grunt_userconfig.json');
	let config = JSON.parse(rawdata);
	let os = process.platform
	let xml_string = undefined;
	if(os.toLowerCase().startsWith("win")) {	    
	    xml_string = fs.readFileSync("c:/opt/digiverso/viewer/config/config_viewer.xml", "utf-8");
	} else {
	    xml_string = fs.readFileSync("/opt/digiverso/viewer/config/config_viewer.xml", "utf-8");
	}
	let viewer_config = XML.parse(xml_string);

	return config.tomcat_dir + "/goobi-viewer-theme-" + viewer_config.viewer.theme.mainTheme + "/WEB-INF/classes";
}

function getConfigDir() {
	return "/opt/digiverso/viewer/config";
}

module.exports = function (grunt) {
	// ---------- VARIABLES ----------
	var banner = '/*!\n'
		+ ' * This file is part of the Goobi viewer - a content presentation and management application for digitized objects.\n'
		+ ' *\n'
		+ ' * Visit these websites for more information.\n'
		+ ' * - http://www.intranda.com\n'
		+ ' * - http://digiverso.com\n'
		+ ' *\n'
		+ ' * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free\n'
		+ ' * Software Foundation; either version 2 of the License, or (at your option) any later version.\n'
		+ ' *\n'
		+ ' * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or\n'
		+ ' * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.\n'
		+ ' *\n'
		+ ' * You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.\n'
		+ ' */';

	// ---------- PROJECT CONFIG ----------
	grunt.initConfig({
		theme: {
			name: 'viewer'
		},
		pkg: grunt.file.readJSON('package.json'),
		src: {
			msgFolder: 'src/main/resources/',
		},
		sync: {
			main: {
        		files: [{
					cwd: '<%=src.msgFolder %>',
					src: ['messages_*.properties'],
					dest: getConfigDir()
				}],
				verbose: true
			},
		},
		watch: {
			messages: {
				files: ['<%=src.msgFolder %>/messages_*.properties'],
				tasks: ['sync'],
				options: {
					reload: true
				}
			},
		},
	});

	// ---------- LOAD TASKS ----------
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-sync');

	// ---------- REGISTER TASKS ----------
	// ----------
    // default task.
    // Default which runs the build task.
	// $ grunt
	grunt.registerTask('default', ['watch']);
	
};
