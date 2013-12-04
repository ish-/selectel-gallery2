module.exports = function(grunt) {
	grunt.initConfig({
		compass: {
			all: {
				config: './config.rb',
			}
		},
		ejs: {
			options: {
				'fs': require('fs'),
			},
			gallery: {
				cwd: 'src',
				src: ['gallery.ejs'],
				dest: 'dist/',
				ext: '.html',
				expand: true
			},
			'gallery-dev': {
				cwd: 'src',
				src: ['gallery.dev.ejs'],
				dest: 'dist/',
				ext: '.html',
				expand: true
			},
			access: {
				cwd: 'src',
				src: ['access.ejs'],
				dest: 'dist/',
				ext: '.html',
				expand: true
			}
		},
		concat: {
			gallery: {
				files: {'.temp/js/gallery.js': [
					'src/js/vendor/jquery.min.js',
					'src/js/vendor/jquery.event.move.js',
					'src/js/vendor/jquery.event.swipe.js',
					'src/js/vendor/jquery.appear.js',
					'.temp/js/gallery.js',
				]}
			},
			'vendor-dev': {
				files: [
					{'dist/js/vendor.js': [
						'src/js/vendor/jquery.min.js',
						'src/js/vendor/jquery.event.move.js',
						'src/js/vendor/jquery.event.swipe.js',
						'src/js/vendor/jquery.appear.js',
					]},
				]
			},
		},
		watch: {
			coffee: {
				files: ['src/js/gallery.coffee'],
				tasks: ['coffee:gallery-dev'],
			}
		},
		coffee: {
			options: {

			},
			gallery: {
				files: {
					'.temp/js/gallery.js': 'src/js/gallery.coffee'
				}
			},
			'gallery-dev': {
				options: {
					bare: true,
				},
				files: {
					'dist/js/app.js': 'src/js/gallery.coffee'
				}
			},
			access: {
				files: {
					'.temp/js/access.js': 'src/js/access.coffee'
				}
			},
		},
		uglify: {
			gallery: {
				files: { '.temp/js/gallery.js': ['.temp/js/gallery.js'] }
			},
			access: {
				files: {'.temp/js/access.js': ['.temp/js/access.js']},
			},
		}
	});

	grunt.loadNpmTasks('grunt-contrib-compass');
	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-uglify');
	grunt.loadNpmTasks('grunt-contrib-concat');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-ejs');

	grunt.registerTask('build:access', ['coffee:access', 'compass', 'uglify:access', 'ejs:access']);
	grunt.registerTask('build:gallery', ['coffee:gallery', 'compass', 'concat:gallery', 'uglify:gallery', 'ejs:gallery']);
	grunt.registerTask('build', ['build:gallery', 'build:access']);

	grunt.registerTask('build:gallery-dev', ['coffee:gallery-dev', 'concat:vendor-dev', 'compass', 'ejs:gallery-dev', 'watch:coffee']);
}
