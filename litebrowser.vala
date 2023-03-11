using Gtk;
using WebKit;
using Json;

namespace Litebrowser {

	public class LiteBrowserTab : Gtk.Box {

		private const string DEFAULT_PROTOCOLL = "https";

		private Regex protocoll_regex;
		private Litebrowser.Logger logger;
		private Litebrowser.Configs configs;

		private bool incognito;

		private WebKit.WebView web_view;
		private Gtk.ToolButton button_back;
		private Gtk.ToolButton button_forward;
		private Gtk.ToolButton button_reload;
		private Gtk.ToolButton button_home;
		private Gtk.ToolButton button_settings;
		private Gtk.ToolButton button_bookmarks;
		private Gtk.Entry  url_bar;

		public LiteBrowserTab(Litebrowser.Configs configs, Regex procotoll_regex, bool incognito) {
			this.logger = new Litebrowser.Logger();
			this.logger.entering("LiteBrowserTab","__new__");
			this.configs = configs;
			this.incognito = incognito;
			this.protocoll_regex = procotoll_regex;
		   	// create toolbar
			Gtk.Toolbar topbar = this.create_topbar();
			// create web_view
			this.create_webview();
			// create box
			this.set_orientation(Gtk.Orientation.VERTICAL);
			this.set_spacing(0);
			// create box
			this.pack_start (topbar, false, true, 0);
			this.pack_start (this.web_view, true, true, 0);
			this.show_all();
			this.url_bar.grab_focus();
			this.logger.exiting("LiteBrowserWindow","__new__");
        }
        
		private Gtk.Toolbar create_topbar () {
	        this.logger.entering("LiteBrowserTab","create_topbar");
            this.logger.debug("Create buttons ...");
            Gtk.Image img = new Gtk.Image.from_icon_name ("go-previous", Gtk.IconSize.SMALL_TOOLBAR);
			this.button_back = new Gtk.ToolButton (img, null);
            img = new Gtk.Image.from_icon_name ("go-next", Gtk.IconSize.SMALL_TOOLBAR);
			this.button_forward = new Gtk.ToolButton (img, null);
            img = new Gtk.Image.from_icon_name ("view-refresh", Gtk.IconSize.SMALL_TOOLBAR);
			this.button_reload = new Gtk.ToolButton (img, null);
            img = new Gtk.Image.from_icon_name ("gtk-home", Gtk.IconSize.SMALL_TOOLBAR);
			this.button_home = new Gtk.ToolButton(img, null);
	        img = new Gtk.Image.from_icon_name ("gtk-about", Gtk.IconSize.SMALL_TOOLBAR);
			this.button_bookmarks = new Gtk.ToolButton(img, null);
	        img = new Gtk.Image.from_icon_name ("gtk-preferences", Gtk.IconSize.SMALL_TOOLBAR);
			this.button_settings = new Gtk.ToolButton(img, null);
	        this.logger.debug("Create url_bar ...");
            this.url_bar = new Entry ();
            Gtk.ToolItem url_bar_tool = new Gtk.ToolItem();
            url_bar_tool.add(this.url_bar);
            url_bar_tool.set_expand(true);
			this.logger.debug("Connect signals ...");
            this.url_bar.activate.connect (this.on_goto);
			this.button_back.clicked.connect (this.go_back);
            this.button_forward.clicked.connect (this.go_forward);
            this.button_reload.clicked.connect (this.reload);
            this.button_bookmarks.clicked.connect (() => { go_to("about:bookmarks"); });
            this.button_home.clicked.connect(() => { go_to("about:home"); });
			this.button_settings.clicked.connect(() => { go_to("about:configs"); });
			this.logger.debug("Create tooolbar ...");
            Gtk.Toolbar toolbar = new Gtk.Toolbar ();
            toolbar.add (this.button_back);
            toolbar.add (this.button_forward);
            toolbar.add (this.button_reload);
            toolbar.add(url_bar_tool);
			toolbar.add(this.button_home);
			toolbar.add(this.button_bookmarks);
			toolbar.add(this.button_settings);
            this.logger.exiting("LiteBrowserTab","create_topbar");
			return toolbar;
        }

		private void create_webview() {
			this.logger.entering("LiteBrowerTab","create_webview");
			this.web_view = new WebKit.WebView();
			WebKit.Settings settings = this.web_view.get_settings();
			settings.enable_back_forward_navigation_gestures = true;
			settings.enable_javascript = this.configs.javascript;
			settings.enable_page_cache = this.configs.cache;
			if (!this.incognito) {
				string c_file = this.configs.cookies_file.replace("~",Environment.get_home_dir ()).replace("${HOME}",Environment.get_home_dir ());
				this.logger.debug("Cookies file: " + c_file);
				this.web_view.get_website_data_manager().get_cookie_manager().set_persistent_storage(c_file, CookiePersistentStorage.TEXT);
				switch (this.configs.cookies_policy.up()) {
					case "ALWAYS":
						this.web_view.get_website_data_manager().get_cookie_manager().set_accept_policy(CookieAcceptPolicy.ALWAYS);
						break;
					case "MINIMAL":
						this.web_view.get_website_data_manager().get_cookie_manager().set_accept_policy(CookieAcceptPolicy.NO_THIRD_PARTY);
						break;
					case "NEVER":
					default:
						this.web_view.get_website_data_manager().get_cookie_manager().set_accept_policy(CookieAcceptPolicy.NEVER);
						break;
				}
			}
			// menu
			this.web_view.context_menu.connect((menu, event, hit) => {
				this.logger.entering("LiteBrowerTab","context_menu");
				this.logger.debug("uri: " + hit.link_uri);
				if (!hit.context_is_editable() && hit.context_is_link()) {
					menu.remove_all();
					if (!hit.link_uri.has_prefix("javascript:")) {
						SimpleAction action = new SimpleAction("new-tab",null);
						action.activate.connect(() => {
							LiteBrowserWindow app = this.get_window_parent();
							app.open_in_tab(hit.link_uri);
						});
						ContextMenuItem item = new WebKit.ContextMenuItem.from_gaction(action,"Open in new tab",null);
						menu.append(item);
						if (!this.incognito) {
							action = new SimpleAction("new-window",null);
							action.activate.connect(() => {
								LiteBrowserWindow app = this.get_window_parent();
								app.open_in_window(hit.link_uri, false);
							});
							item = new WebKit.ContextMenuItem.from_gaction(action,"Open in new window",null);
							menu.append(item);
						}
						action = new SimpleAction("new-incognito",null);
						action.activate.connect(() => {
							LiteBrowserWindow app = this.get_window_parent();
							app.open_in_window(hit.link_uri,true);
						});
						item = new WebKit.ContextMenuItem.from_gaction(action,"Open in new incognito window",null);
						menu.append(item);
						item = new WebKit.ContextMenuItem.from_stock_action(WebKit.ContextMenuAction.COPY_LINK_TO_CLIPBOARD);
						menu.append(item);
					}
				}
				return false;
			});
			this.web_view.decide_policy.connect((source, decision, type) => {
				this.logger.entering("LiteBrowerTab","decide_policy");
				// convert to NavigationPolicyDecision
				switch (type) {
					case PolicyDecisionType.NAVIGATION_ACTION:
						this.logger.debug("Policy: navigation");
						WebKit.NavigationPolicyDecision web_decision = (WebKit.NavigationPolicyDecision) decision;
						WebKit.NavigationAction action = web_decision.get_navigation_action();
						// check if navigation type is link click
						if (action.get_navigation_type() == NavigationType.LINK_CLICKED) {
							// check the mouse middle click
							uint mouse_button = action.get_mouse_button();
							this.logger.debug("Mouse button: " + mouse_button.to_string());
							// 0 = no mouse button
							if (mouse_button == 0) return false;
							// check the ctrl click
							uint key_mod = action.get_modifiers();
							this.logger.debug("Modifiers: " + key_mod.to_string());
							if ((mouse_button == 1 && key_mod == 4) || 
								(mouse_button == 2 && key_mod == 0)) {
									// open in a new tab
									LiteBrowserWindow app = this.get_window_parent();
									app.open_in_tab(action.get_request().get_uri());
									decision.ignore();
									return true;
							} 
							if (mouse_button == 1 && key_mod == 1) {
								LiteBrowserWindow app = this.get_window_parent();
								app.open_in_window(action.get_request().get_uri());
								decision.ignore();
								return true;
							}
						}
						return false;
					case PolicyDecisionType.NEW_WINDOW_ACTION:
						this.logger.debug("Policy: new_window");
						WebKit.NavigationPolicyDecision web_decision = (WebKit.NavigationPolicyDecision) decision;
						WebKit.NavigationAction action = web_decision.get_navigation_action();
						// open in a new tab
						LiteBrowserWindow app = this.get_window_parent();
						app.open_in_tab(action.get_request().get_uri());
						decision.ignore();
						return true;
					case PolicyDecisionType.RESPONSE:
						this.logger.debug("Policy: response");
						// check if is a download
						WebKit.ResponsePolicyDecision web_decision = (WebKit.ResponsePolicyDecision) decision;
						this.logger.debug("Mime supported=" + (web_decision.is_mime_type_supported()?"yes":"no"));
						if (!web_decision.is_mime_type_supported()) {
							URIResponse response = web_decision.get_response();
							this.logger.debug("URI: " + response.get_uri());
							this.logger.debug("mime: " + response.get_mime_type());
							decision.download();
							return true;
						}
						return false;
					default:
						this.logger.debug("Policy: none");
						return false;
				}
			});
			this.web_view.load_changed.connect ((source,evt) => {
				this.update_bar();
				if (evt == WebKit.LoadEvent.FINISHED) {
					GLib.Timeout.add(500, () => {
						Gtk.Notebook parent = (Gtk.Notebook) this.get_parent();
						Gtk.Box box = (Gtk.Box) parent.get_tab_label(this);
						Gtk.Label label = (Gtk.Label) box.get_children().first().data;
						string title = this.web_view.get_title();
						if (title != null && title.length > 0) {
							label.set_tooltip_text(title);
							if (title.length > 20) {
								title = title.substring(0,20) + "...";
							}
							label.set_label(title);
						}
						// save history
						string uri = this.web_view.get_uri();
						if (uri.has_prefix("about:") || uri.has_prefix("clear:")) return true;
						if (this.configs.save_history && 
							this.configs.history.find_custom(uri,strcmp) == null) {
							this.configs.history.append(uri);
							this.logger.debug("Added to list: " + 
								this.configs.history.find_custom(uri,strcmp).data);
						}
						return false;
					});
				}
			});
			this.logger.exiting("LiteBrowerTab","create_webview");
		}

		private LiteBrowserWindow get_window_parent() {
			Gtk.Notebook parent = (Gtk.Notebook) this.get_parent();
			Gtk.Box box = (Gtk.Box) parent.get_parent();
			return (LiteBrowserWindow) parent.get_parent();
		}

		private void go_back() { this.web_view.go_back(); }
		
		private void go_forward() { this.web_view.go_forward(); }
		
		private void reload() { this.web_view.reload(); }
		
		private void update_bar () {
			this.logger.entering("LiteBrowserTab", "update_buttons");
			this.button_back.sensitive = this.web_view.can_go_back ();
            this.button_forward.sensitive = this.web_view.can_go_forward ();
            this.url_bar.set_text(this.web_view.get_uri());
			this.logger.exiting("LiteBrowserTab", "update_buttons");
        }

		private void on_goto () {
			this.logger.entering("LiteBrowserTab", "on_goto");
            string url = this.url_bar.text;
			this.logger.debug("Read url: " + url);
            this.go_to(url);
			this.logger.exiting("LiteBrowserTab", "on_activate");
        }

        public void go_to(string url) {
			this.logger.entering("LiteBrowserTab", "go_to");
        	switch (url) {
				case "about:new":
				case "about:tab":
        		case "about:blank":
					this.web_view.load_plain_text("");
					break;
				case "about:history":
					string hist_string="<html><head><title>History</title></head>";
					hist_string +="<body><h3>History</h3><ul>";
					this.configs.history.foreach((entry) => { 
						hist_string += "<li><a href='" + entry + "'>" + entry + "</a></li>"; 
					});
					hist_string +="</ul></body></html>";
					this.web_view.load_html(hist_string,url);
					break;
				case "about:setting":	
				case "about:settings":
				case "about:config":
				case "about:configs":
					this.web_view.load_plain_text(this.configs.to_string(null,true));
					break;
				case "about:bookmarks":
					//TODO 
        		case "about:home":
        			this.web_view.load_uri(this.configs.home);
					this.logger.info("Load " + this.configs.home);
        			break;
        		default:
		            if (url.contains("://")) {
						string protocoll = url.split("://")[0];
						if (protocoll == "http" || protocoll == "https")
							this.web_view.load_uri(url);
						else
							this.web_view.load_plain_text("Unsupported protocoll: " + protocoll);
					} else
						this.web_view.load_uri("https://" + url);
					break;
		    }
			this.logger.exiting("LiteBrowserTab", "go_to");
        }
	}

    public class LiteBrowserWindow : Window {

        private Litebrowser.Logger logger;
		private Litebrowser.Configs configs;

		private Regex protocoll_regex;
        
		private Gtk.Notebook tab_window;
		private bool incognito;
        
		private LiteBrowserApplication app;
		private string win_id;

        public LiteBrowserWindow (LiteBrowserApplication app,string id, Litebrowser.Configs configs, Litebrowser.Logger logger, string? url = null, bool? incognito = false) {
        	this.logger = logger;
        	this.logger.entering("LiteBrowserWindow","__new__");
			this.app = app;
			this.win_id = id;
        	// parse configurations
			this.configs = configs;
			this.incognito = incognito;
        	this.set_title(this.configs.title + (this.incognito?" - Private":""));
			string[] resolution = this.configs.resolution.up().split("X");
        	int x = int.parse(resolution[0]);
        	int y = int.parse(resolution[1]);
            set_default_size (x, y);
			try {
				this.protocoll_regex = new Regex (".*://.*");
		   	} catch (RegexError e) {
			   critical ("Regex error: %s\n", e.message);
		   	}
			Litebrowser.LiteBrowserTab tab = new Litebrowser.LiteBrowserTab(this.configs, this.protocoll_regex, this.incognito);
			Gtk.Box label = this.create_button_tab(tab);
			this.tab_window = new Gtk.Notebook();
			this.tab_window.set_scrollable(true);
			this.tab_window.append_page(tab,label);
			Gtk.Button new_tab = new Gtk.Button.from_icon_name("gtk-add", Gtk.IconSize.MENU);
			new_tab.set_relief(ReliefStyle.NONE);
			new_tab.clicked.connect(() => { 
				this.open_in_tab("about:tab");
			});
			Gtk.Box new_tab_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
			new_tab_box.pack_start(new_tab,false,false,0);
			new_tab_box.show_all();
			this.tab_window.set_action_widget(new_tab_box,PackType.START);
			this.tab_window.show_all();
			this.add(tab_window);
			this.show_all();
			if (url == null) url = "about:home";
			tab.go_to(url);
            this.destroy.connect (this.exit);
        	this.logger.exiting("LiteBrowserWindow","__new__");
        }
        
		public void open_in_window(string uri, bool? incognito = null) {
			this.logger.entering("LiteBrowserWindow", "open_in_window");
			if (incognito == null) incognito = this.incognito;
			this.app.new_window(uri, incognito);
			this.logger.exiting("LiteBrowserWindow", "open_in_window");
		}

		public void open_in_tab(string uri) {
			this.logger.entering("LiteBrowserWindow", "open_in_tab");
			this.logger.debug("Open new tab with url: " + uri);
			Litebrowser.LiteBrowserTab obj_tab = new Litebrowser.LiteBrowserTab(this.configs, this.protocoll_regex, this.incognito);
			Gtk.Box obj_label = this.create_button_tab(obj_tab);
			this.logger.debug("Box with web_view created, navigate to " + uri);
			obj_tab.go_to(uri);
			int position = this.tab_window.get_current_page() + 1;
			this.logger.debug("Add tab to tab list");
			this.tab_window.insert_page(obj_tab,obj_label,position);
			this.tab_window.set_current_page(position);
			this.logger.exiting("LiteBrowserWindow", "open_in_tab");
		}

		private Gtk.Box create_button_tab(Litebrowser.LiteBrowserTab tab) {
			Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
			Gtk.Label label = new Gtk.Label(this.configs.title);
			Gtk.Button close = new Gtk.Button.from_icon_name("gtk-cancel", Gtk.IconSize.MENU);
			close.set_relief(ReliefStyle.NONE);
			close.clicked.connect(() => {
				this.remove_tab(tab);
			});
			box.pack_start(label,false,false,0);
			box.pack_start(close,false,false,1);
			box.show_all();
			return box;
		}

		private void remove_tab(Litebrowser.LiteBrowserTab tab) {
			int page_num = this.tab_window.page_num(tab);
			this.tab_window.remove_page(page_num);
			if (this.tab_window.get_n_pages() == 0)
				this.exit();
		}

		private void exit() {
			this.destroy();
        	this.app.exit(this.win_id);
        }
    }

	public class LiteBrowserApplication {

		private Configs configs;
		private Logger logger;

		private HashTable<string,LiteBrowserWindow> windows = new HashTable<string,LiteBrowserWindow>(str_hash,str_equal); 

		public LiteBrowserApplication() {
			this.logger = new Logger(true);
    	    this.configs = new Configs(this.logger);
			if (!this.configs.parse_config()) {
				this.configs.save();
				this.configs.parse_config();
			}
		}

		public void new_window(string? uri = "about:home", bool? incognito = false) {
			this.logger.info("Open new " + (incognito?" private ":"") + "window and go to " + uri );
			string id = this.windows.size().to_string();
			LiteBrowserWindow w = new LiteBrowserWindow(this,id,this.configs, this.logger, uri, incognito);
			this.logger.info("window loaded");
			this.windows.insert(id, w);
			w.show_all();
		}
		
		public void exit(string id) {
			this.windows.remove(id);
			if (this.windows.size() == 0) {
				this.configs.save();
				Gtk.main_quit();
			}
		}

   		public static int main (string[] args) {
    	    Gtk.init (ref args);
			LiteBrowserApplication app = new LiteBrowserApplication();
			app.new_window();
	        Gtk.main ();
	        return 0;
		}
	}
}