using Gtk;
using WebKit;
using Json;

namespace Litebrowser {

	public class LoggerRecord {
		public LoggerRecord parent; 
		public string class_name;
		public string method_name;
		public LoggerRecord(string class_name, string method_name, LoggerRecord? parent) {
			this.class_name = class_name;
			this.method_name = method_name;
			this.parent = parent;
		}
		
		public bool has_parent() { return this.parent != null; }
	}

    public class Logger {
        
        private const string MESSAGE_FORMAT = "<%s> [%s] %s.%s(): %s";
        private bool enabled;
        private LoggerRecord current_log;
        
    	public Logger(bool enabled = false) {
    		this.enabled = enabled;
    		this.current_log = new LoggerRecord("root","main",null);
    	}
    	
    	public void entering(string class_name, string method_name) {
    		LoggerRecord source = new LoggerRecord(class_name, method_name, this.current_log);
			this.current_log = source;
    		this.trace("Entering %s.%s".printf(class_name, method_name));
    	}
    	public void exiting(string class_name, string method_name) {
    		this.trace("Exiting %s.%s".printf(class_name, method_name));
    		if (this.current_log.has_parent()) {
    			this.current_log = this.current_log.parent;
			} else {
	    		this.current_log = new LoggerRecord("root","main",null);
    		}
    	}
    	public void info(string message) {
	    	this.logp(this.current_log.class_name, this.current_log.method_name, "info", message);
    	}
    	public void warn(string message) {
	    	this.logp(this.current_log.class_name, this.current_log.method_name, "warning", message);
    	}
    	public void severe(string message) {
    		this.logp(this.current_log.class_name, this.current_log.method_name, "severe", message);
    	}
    	public void debug(string message) {
	    	this.logp(this.current_log.class_name, this.current_log.method_name, "debug", message);
    	}
    	public void trace(string message) {
    		this.logp(this.current_log.class_name, this.current_log.method_name, "trace", message);
    	}
    	
    	public void logp(string class_name, string method_name, string level, string message) {
    		if (this.enabled) {
	    		string date_now = new DateTime.now_local().to_string();
    			string message_to_print = MESSAGE_FORMAT.printf(date_now, level.up(), class_name, method_name, message);
    			print("%s\n".printf(message_to_print));
			}
    	}
    }

    public class WindowBrowser : Window {

        private List<TabBrowser> tabs;
		private Litebrowser.Logger logger;
		private Litebrowser.Configs configs;

        public WindowBrowser (Litebrowser.Configs configs, Litebrowser.Logger logger) {
        	this.logger = logger;
        	this.logger.entering("WindowBrowser","__new__");
        	this.configs = configs;
        	string[] resolution = this.configs.resolution.up().split("X");
        	int x = int.parse(resolution[0]);
        	int y = int.parse(resolution[1]);
            set_default_size (x, y);
            this.tabs = new List<TabBrowser>();
            TabBrowser tab = new Litebrowser.TabBrowser(this);
            this.tabs.append(tab);
            this.destroy.connect (this.exit);
        	this.logger.exiting("WindowBrowser","__new__");
        }
        
        public string get_home() { return this.configs.home; }
        public string get_app_title() { return this.configs.title; }
        public Litebrowser.Logger get_logger() { return this.logger; }
        
        private void exit() {
        	this.configs.save();
	        Gtk.main_quit();
        }
    }

    public class TabBrowser {

        private const string DEFAULT_PROTOCOLL = "https";

		private Litebrowser.Logger logger;
        private Regex protocoll_regex;
        private Entry url_bar;
        private WebView web_view;
        private Label status_bar;
        private ToolButton back_button;
        private ToolButton forward_button;
        private ToolButton reload_button;
        private WindowBrowser parent;

        public TabBrowser (WindowBrowser win, string url="about:home") {
            this.parent = win;
            this.logger = this.parent.get_logger();
        	this.logger.entering("TabBrowser","__new__");
        	this.parent.title = this.parent.get_app_title();
            try {
                 this.protocoll_regex = new Regex (".*://.*");
            } catch (RegexError e) {
                critical ("Regex error: %s\n", e.message);
            }
            create_widgets ();
            connect_signals ();
            this.url_bar.grab_focus ();
            this.url_bar.text = url;
            this.go_to(url);
			this.logger.debug("Connect destroy window to quit");
			this.logger.exiting("TabBrowser","__new__");
        }

        private void create_widgets () {
	        this.logger.entering("TabBrowser","create_widgets");
            this.logger.debug("Create buttons ...");
            Gtk.Image img = new Gtk.Image.from_icon_name ("go-previous", Gtk.IconSize.SMALL_TOOLBAR);
                      this.back_button = new Gtk.ToolButton (img, null);
            img = new Gtk.Image.from_icon_name ("go-next", Gtk.IconSize.SMALL_TOOLBAR);
                      this.forward_button = new Gtk.ToolButton (img, null);
            img = new Gtk.Image.from_icon_name ("view-refresh", Gtk.IconSize.SMALL_TOOLBAR);
                      this.reload_button = new Gtk.ToolButton (img, null);
	        this.logger.debug("Create url_bar ...");
            this.url_bar = new Entry ();
            Gtk.ToolItem url_bar_tool = new Gtk.ToolItem();
            url_bar_tool.add(this.url_bar);
            url_bar_tool.set_expand(true);
			this.logger.debug("Create tooolbar ...");
            var toolbar = new Toolbar ();
            toolbar.add (this.back_button);
            toolbar.add (this.forward_button);
            toolbar.add(url_bar_tool);
            toolbar.add (this.reload_button);
            this.logger.debug("Create web_view ...");
            this.web_view = new WebView ();
            var scrolled_window = new ScrolledWindow (null, null);
            scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
            scrolled_window.add (this.web_view);
            this.logger.debug("Create status_bar ...");
            this.status_bar = new Label ("New tab") ;
            this.status_bar.xalign = 0;
            this.logger.debug("Create box tab ...");
            Box tab = new Box (Gtk.Orientation.VERTICAL, 0);
            tab.pack_start (toolbar, false, true, 0);
            tab.pack_start (scrolled_window, true, true, 0);
            tab.pack_start (this.status_bar, false, true, 0);
            this.logger.debug("Add tab to window ...");
            this.parent.add(tab);
			this.logger.exiting("TabBrowser", "create_widgets");
        }

        private void connect_signals () {
			this.logger.entering("TabBrowser", "connect_signals");
			this.logger.debug("Connect url_bar event to load url ...");
            this.url_bar.activate.connect (on_activate);
			this.logger.debug("Connect web_view event load_changed ...");
            this.web_view.load_changed.connect ((source, evt) => {
	            this.url_bar.text = source.get_uri ();
                this.parent.title = this.web_view.title;
                if (evt == LoadEvent.FINISHED) {
	                this.status_bar.set_label("Loaded %s".printf(this.url_bar.text));
	            }
                update_buttons ();
            });
			this.logger.debug("Connect web_view button events ...");
            this.back_button.clicked.connect (this.web_view.go_back);
            this.forward_button.clicked.connect (this.web_view.go_forward);
            this.reload_button.clicked.connect (this.web_view.reload);
			this.logger.exiting("TabBrowser", "connect_signals");
        }

        private void update_buttons () {
			this.logger.entering("TabBrowser", "update_buttons");
            this.back_button.sensitive = this.web_view.can_go_back ();
            this.forward_button.sensitive = this.web_view.can_go_forward ();
			this.logger.exiting("TabBrowser", "update_buttons");
        }

        private void on_activate () {
			this.logger.entering("TabBrowser", "on_activate");
            var url = this.url_bar.text;
			this.logger.debug("Read url: %s".printf(url));
            this.go_to(url);
			this.logger.exiting("TabBrowser", "on_activate");
        }

        private void go_to(string url) {
			this.logger.entering("TabBrowser", "go_to");
        	var turl = url;
        	switch (url) {
        		case "about:home":
        			turl = this.parent.get_home();
        			break;
        		default:
		            if (!this.protocoll_regex.match (url)) {
        		        turl = "%s://%s".printf (DEFAULT_PROTOCOLL, url);
        		    }
        		    break;
		    }
			this.logger.info("Load %s".printf(turl));
			this.status_bar.set_label("Loading %s ...".printf(turl));
            this.web_view.load_uri (turl);
			this.logger.exiting("TabBrowser", "go_to");
        }
    }

	public class Configs {

		private Logger logger;
		public List<string> mimes = new List<string>();
		public List<string> history = new List<string>();
		public Configs(Logger logger) { 
			this.logger = logger; 
		}

		public string config_file { get; set; default = "~/.config/litebrowser/options.json"; }	
		public string title { get; set; default = "LiteBrowser"; } 
		public string resolution { get; set; default = "800x600"; } 
		public string home { get; set; default = "https://www.icapito.it"; }
		public string search { get; set; default = "https://www.google.it/search?q=${text}"; }
		public string cookies { get; set; default = "~/.config/litebrowser/cookies.txt"; }
		public HashTable<string, string> bookmarks { get; set; default = new HashTable<string,string>(str_hash, str_equal); }
		public bool save_history { get; set; default = true; }
		
		public void parse_config() {
			this.logger.entering("Configs","parse_config");
			string file_name = this.config_file.replace("~",Environment.get_home_dir())
						.replace("${HOME}",Environment.get_home_dir());
			File file = File.new_for_path (file_name);
			// Check if a particular file exists:
			if (!file.query_exists ()) { return; }
			try {
				Parser json_parser = new Parser();
				json_parser.load_from_file(file_name);
				Json.Node node_root = json_parser.get_root();
				Json.Object root = node_root.get_object();
				foreach (unowned string name in root.get_members ()) {
					switch (name) {
						case "resolution": 
							this.resolution = root.get_string_member(name);
							break;
						case "home": 
							this.home = root.get_string_member(name);
							break;
						case "search": 
							this.search = root.get_string_member(name);
							break;
						case "cookies": 
							this.cookies = root.get_string_member(name);
							break;
						case "save_history": 
							this.save_history = root.get_boolean_member(name);
							break;
						case "mimes": 
							Json.Array temp = root.get_array_member(name);
							this.mimes.foreach((entry) => { this.mimes.remove(entry); });
							foreach (unowned Json.Node item in temp.get_elements ()) {
								this.mimes.append(item.get_string());
							}
							break;
						case "history": 
							Json.Array temp = root.get_array_member(name);
							this.history.foreach((entry) => { this.mimes.remove(entry); });
							foreach (unowned Json.Node item in temp.get_elements ()) {
								this.history.append(item.get_string());
							}
							break;
						case "bookmarks": 
							HashTable<string,string> tmap = new HashTable<string,string>(str_hash, str_equal);
							Json.Array temp = root.get_array_member(name);
							foreach (unowned Json.Node array_item in temp.get_elements ()) {
								// for each element if have a jsonObject with name and url key
								Json.Object item = array_item.get_object();
								tmap.insert(item.get_string_member("name"), item.get_string_member("url"));
							}
							this.bookmarks = tmap;
							break;
						default:
							this.logger.warn("Unmanaged config key: %s".printf(name));
							break;
					}
				}
			} catch (Error e) {
				this.logger.severe("Error parsing config file: %s".printf(e.message));
			} finally {
				this.logger.exiting("Configs", "parse_config");
			}
		}
		
		public string to_string() {
			Json.Builder builder = new Json.Builder ();
			builder.begin_object();
			builder.set_member_name("resolution");
			builder.add_string_value(this.resolution);
			builder.set_member_name("home");
			builder.add_string_value(this.home);
			builder.set_member_name("search");
			builder.add_string_value(this.search);
			builder.set_member_name("cookies");
			builder.add_string_value(this.cookies);
			builder.set_member_name("save_history");
			builder.add_boolean_value(this.save_history);
			builder.set_member_name("mimes");
			builder.begin_array();
			this.mimes.foreach((entry) => { builder.add_string_value(entry); });
			builder.end_array();
			builder.set_member_name("history");
			builder.begin_array();
			this.history.foreach((entry) => { builder.add_string_value(entry); });
			builder.end_array();
			builder.set_member_name("bookmarks");
			builder.begin_array();
			this.bookmarks.foreach((name,url) => {
				Json.Builder sbuilder = new Json.Builder (); 
				sbuilder.begin_object();
				sbuilder.set_member_name("name");
				sbuilder.add_string_value(name);
				sbuilder.set_member_name("url");
				sbuilder.add_string_value(url);
				sbuilder.end_object();
				Json.Node obj = sbuilder.get_root ();
				builder.add_value(obj);
			});
			builder.end_array();
			builder.end_object ();
			Json.Generator generator = new Json.Generator ();
			Json.Node root = builder.get_root ();
			generator.set_root (root);
			return generator.to_data(null);
		}
		
		public void save() {
			this.logger.entering("Configs","save");
			try {
				var file = File.new_for_path (this.config_file.replace("~",Environment.get_home_dir ()).replace("${HOME}",Environment.get_home_dir ()));
		        // Create a new file with this name
    	        var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
	            // Test for the existence of file
	            if (!file.query_exists ()) {
	                this.logger.severe("Unable to create config file %s".printf(this.config_file));
	            } else {
		            // Write text data to file
		            var data_stream = new DataOutputStream (file_stream);
		            data_stream.put_string (this.to_string());
		        }
	        } catch (Error e) {
	        	this.logger.severe("Error during save config file: %s".printf(e.message));
	        } finally {
    			this.logger.exiting("Configs","save");
			}
		}
	}

	public class LiteBrowserApplication {

   		public static int main (string[] args) {
    	    Gtk.init (ref args);
    	    Logger logger = new Logger(true);
    	    Configs configs = new Configs(logger);
			configs.parse_config();
	        var browser = new WindowBrowser (configs,logger);
	        browser.show_all ();
			logger.info("window loaded");
	        Gtk.main ();
	        return 0;
		}
	}
}
