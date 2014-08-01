module.exports = function(grunt) {
	grunt.initConfig({
		compass: {
			all: {
				config: './config.rb',
			}
		},
		ejs: {
			options: {
				fs: require('fs'),
        		DEV: false,
			},
			gallery: {
				cwd: 'src',
				src: ['gallery.ejs'],
				dest: 'dist/',
				ext: '.html',
				expand: true
			},
			'gallery-dev': {
        		options: {DEV: true},
				cwd: 'src',
				src: ['gallery.ejs'],
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
			vendor: {
        files: [
          {'.temp/js/vendor.js': [
            'src/js/vendor/jquery.min.js',
            'src/js/vendor/events.js',
            'src/js/vendor/hammer.min.js',
            // 'src/js/vendor/jquery.event.move.js',
            // 'src/js/vendor/jquery.event.swipe.js',
            'src/js/vendor/jquery.appear.js',
            // 'src/js/vendor/jquery.transitionend.js',
          ]},
        ]
      },
      'vendor-dev': {
        files: [
          {'dist/vendor.js': [
            'src/js/vendor/jquery.min.js',
            'src/js/vendor/hammer.min.js',
            'src/js/vendor/events.js',
            // 'src/js/vendor/jquery.doubletap.js',
            // 'src/js/vendor/jquery.event.move.js',
            // 'src/js/vendor/jquery.event.swipe.js',
            'src/js/vendor/jquery.appear.js',
            // 'src/js/vendor/jquery.transitionend.js',
          ]},
				]
			},
		},
		watch: {
			coffee: {
				files: ['src/js/*.coffee'],
				tasks: ['coffee:gallery-dev'],
			}
		},
		coffee: {
      options: {
					bare: false,
          join: true,
      },
      gallery: {
        files: {
          '.temp/gallery.js': ['src/js/Box.coffee', 'src/js/Explorator.coffee', 'src/js/gallery.coffee']
        }
      },
      'gallery-dev': {
				files: {
					'dist/app.js': ['src/js/Box.coffee', 'src/js/Explorator.coffee', 'src/js/gallery.coffee']
				}
			},
			access: {
				files: {
					'.temp/js/access.js': 'src/js/access.coffee'
				}
			},
		},
    clean: ['.temp', 'dist'],
		uglify: {
			gallery: {
				files: { '.temp/js/gallery.min.js': ['.temp/js/vendor.js', '.temp/js/gallery.js'] }
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
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-ejs');

	grunt.registerTask('build:access', ['clean', 'coffee:access', 'compass', 'uglify:access', 'ejs:access']);
	grunt.registerTask('build:gallery', ['clean', 'coffee:gallery', 'compass', 'concat:vendor', 'uglify:gallery', 'ejs:gallery']);
	grunt.registerTask('build', ['build:gallery', 'build:access']);

  grunt.registerTask('build:gallery-dev', ['clean', 'coffee:gallery-dev', 'concat:vendor-dev', 'compass', 'ejs:gallery-dev', 'watch:coffee']);
	grunt.registerTask('build:gallery-fast-dev', ['coffee:gallery-dev', 'concat:vendor-dev', 'ejs:gallery-dev', 'watch:coffee']);
}
