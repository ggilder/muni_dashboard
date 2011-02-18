function muni_module(){
	this.init = function(host) {
		$this = this
		$(host).append(this.moduleMarkup())
		this.contents = $('#muni ul')
		
		this.last_updated = $('#muni .last_updated')
		this.last_updated_date = new Date()
		
		this.item_tmpl = '<li><h2 class="route">${route}</h2><div class="item-content"><h3 class="direction">${direction}</h3><h4 class="stop">@ ${stop}</h4><div class="predictions">${predictions}</div></div></li>'
		this.template_name = 'muni_item_template'
		$.template(this.template_name, this.item_tmpl)
		
		window.setInterval(function(){ $this.updateStatus() }, 5 * 1000)
		window.setInterval(function(){ $this.updateContent() }, 16 * 1000)
		
		this.updateContent()
	}
	this.updateStatus = function() {
		var d = new Date()
		var update_time = ''
		// diff in milliseconds
		var date_diff = (d.getTime() - this.last_updated_date.getTime())
		// if updated less than 1:05 ago
		if (date_diff < (65 * 1000)) {
			var date_diff_seconds = Math.round(date_diff / 1000)
			if (date_diff_seconds < 13) {
				update_time = 'just now'
			} else if (date_diff_seconds < 28) {
				update_time = '15 seconds ago'
			} else if (date_diff_seconds < 43) {
				update_time = '30 seconds ago'
			} else if (date_diff_seconds < 58) {
				update_time = '45 seconds ago'
			} else {
				update_time = 'about a minute ago'
			}
		} else {
			update_time = this.last_updated_date.toRelativeTime()
		}
		this.last_updated.text('Updated ' + update_time)
	}
	this.updateContent = function() {
		var $this = this
		$.getJSON('/muni.json', function(result){
			if (result['data'].length > 0){
				var out = $.tmpl($this.template_name, result['data'])
				$this.contents.html(out)
				$this.last_updated_date = new Date(result['as_of'] * 1000)
				$this.updateStatus()
			} else {
				$this.contents.html('<li class="error">Error: no muni data received!</li>')
			}
		})
	}
	this.moduleMarkup = function() {
		return '<div id="muni" class="module"><h2 class="module_title">MUNI</h2><ul></ul><div class="last_updated"></div></div>'
	}
}

jQuery(function($) {
    muni = new muni_module()
    muni.init('#modules')
})