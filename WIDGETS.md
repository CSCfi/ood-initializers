# Widgets

After creating a file (`_<widgetname>.html.erb`) for the widget in `ood-initializers/widgets/`, the widget can be used in `ood-initializers/ondemand.d/dashboard.yml`.

## Styling

### Base container
A widget container styled according to `csc-ui` can be created by using the `widgets/container` widget:
```
<%= render :layout => 'widgets/container', :locals => {:title => "My widget", :id => "my_widget", :class => "my-widget-class" } do %>
  The content of the widget goes here
<% end %>
```

Note that `csc-ui` is not used in the widgets, but the style has been copied to match `csc-ui`.

### Custom CSS in widget

As style tags in the HTML body is not valid HTML and not guaranteed to work in all browsers, CSS needs t o be added using Javascript in the widget:
```
<script>
  (function() {
      const style = document.createElement('style');
      style.textContent = `
        .my-widget-class {
          color: #F00;
        }
        #my_widget {
          background: #FFF;
        }
      `;
      document.head.appendChild(style);
    })();
</script>
```

## Separating complex Ruby code
In some cases it might be good to separate parts of the Ruby code for the widget.
To do that you can create a Ruby script in `ood-initializers/dashboard` and add the script to both `ood_install.sh` (copy script when deploying) and `ood.rb` (require script during OOD initialization).
