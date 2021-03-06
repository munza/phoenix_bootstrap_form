defmodule PhoenixBootstrapForm do

  alias Phoenix.HTML.{Tag, Form}

  def select(form = %Form{}, field, options, opts \\[]) do
    draw_generic_input(:select, form, field, options, opts)
  end

  [:text_input, :file_input, :email_input, :password_input, :textarea, :telephone_input]
    |> Enum.each(fn(method) ->
      def unquote(method)(form = %Form{}, field, opts \\ []) when is_atom(field) do
        draw_generic_input(unquote(method), form, field, nil, opts)
      end
    end)

  def checkbox(form = %Form{}, field, opts \\ []) do
    {label_opts, opts}  = Keyword.pop(opts, :label, [])
    {input_opts, _}     = Keyword.pop(opts, :input, [])
    {help, input_opts}  = Keyword.pop(input_opts, :help)

    label     = Keyword.get(label_opts, :text, Form.humanize(field))
    checkbox  = Form.checkbox(form, field, class: "form-check-input")
    help      = draw_help(help)
    error     = draw_error_message(get_error(form, field))

    content = [
      draw_form_check(checkbox, label, input_opts[:inline]),
      help,
      error
    ]

    draw_form_group("", content)
  end

  def radio_button(form, field, values, opts \\ [])
  def radio_button(form = %Form{}, field, values, opts) when is_list(values) do
    values = Enum.into(values, %{}, fn(value) ->
      {Form.humanize(value), value}
    end)
    radio_button(form, field, values, opts)
  end

  def radio_button(form = %Form{}, field, values, opts) when is_map(values) do
    {input_opts, opts} = Keyword.pop(opts, :input, [])
    {help, input_opts} = Keyword.pop(input_opts, :help)

    help  = draw_help(help)
    error = draw_error_message(get_error(form, field))

    radios = Enum.map(values, fn({label, value}) ->
      draw_form_check(Form.radio_button(form, field, value, class: "form-check-input"), label, input_opts[:inline])
    end)

    content = [radios, help, error]

    draw_form_group(draw_label(form, field, opts), content)
  end

  def submit(form = %Form{}, opts) when is_list(opts) do
    draw_submit(form, nil, opts)
  end
  def submit(form = %Form{}, label),             do: draw_submit(form, label, [])
  def submit(form = %Form{}, label, opts \\ []), do: draw_submit(form, label, opts)
  def submit(form = %Form{}),                    do: draw_submit(form, nil, [])

  defp merge_css_classes(opts) do
    {classes, rest} = Keyword.split(opts, [:class])
    class = classes
      |> Keyword.values
      |> Enum.join(" ")
    [class: class] ++ rest
  end

  defp is_valid_class(form, field) do
    case has_error?(form, field) do
      true  -> "is-invalid"
      _     -> ""
    end
  end

  defp has_error?(%Form{errors: errors}, field) do
    Keyword.has_key?(errors, field)
  end
  defp has_error?(_, _), do: false

  defp get_error(form, field) do
    case has_error?(form, field) do
      true ->
        msg   = form.errors[field] |> elem(0)
        opts  = form.errors[field] |> elem(1)
        format_error_message(msg, opts)
      _ -> nil
    end
  end

  defp format_error_message(msg, []), do: msg
  defp format_error_message(msg, opts) do
    {key, value} = hd(opts)
    String.replace(msg, "%{#{key}}", to_string(value))
    |> format_error_message(tl(opts))
  end

  defp draw_generic_input(type, form, field, options, opts) do
    draw_form_group(
      draw_label(form, field, opts),
      draw_control(type, form, field, options, opts)
    )
  end

  defp draw_control(type, form, field, options, opts) do
    is_valid_class = is_valid_class(form, field)
    input_opts = [class: "form-control #{is_valid_class}"] ++ Keyword.get(opts, :input, [])
    {prepend, input_opts} = Keyword.pop(input_opts, :prepend)
    {append, input_opts}  = Keyword.pop(input_opts, :append)
    {help, input_opts}    = Keyword.pop(input_opts, :help)

    input = draw_input(type, form, field, options, input_opts)
      |> draw_input_group(prepend, append)

    help  = draw_help(help)
    error = draw_error_message(get_error(form, field))

    [input, help, error]
  end

  defp draw_input(:select, form, field, options, opts) do
    Form.select form, field, options, merge_css_classes(opts)
  end

  defp draw_input(type, form, field, nil, opts) do
    apply(Form, type, [form, field, merge_css_classes(opts)])
  end

  defp draw_form_group(label, content) do
    Tag.content_tag :div, class: "form-group" do
      [label, content]
    end
  end

  defp draw_label(form, field, opts) when is_atom(field) do
    label_opts = Keyword.get(opts, :label, [])
    {text, label_opts} = Keyword.pop(label_opts, :text, Form.humanize(field))
    text_value =
      case Keyword.get(label_opts, :required, false) do
        true -> text <> " *"
        false -> text
      end

    Form.label(form, field, text_value, merge_css_classes(label_opts))
  end

  defp draw_input_group(input, nil, nil), do: input
  defp draw_input_group(input, prepend, append) do
    Tag.content_tag(:div, class: "input-group") do
      [draw_input_group_addon(prepend), input, draw_input_group_addon(append)]
    end
  end

  defp draw_input_group_addon(nil), do: ""
  defp draw_input_group_addon(content) do
    Tag.content_tag(:div, content, class: "input-group-addon")
  end

  defp draw_help(nil), do: ""
  defp draw_help(content) do
    Tag.content_tag(:small, content, class: "form-text text-muted")
  end

  defp draw_submit(%Form{}, label, opts) do
    {alternative, opts} = Keyword.pop(opts, :alternative, "")
    opts = [class: "btn"] ++ opts
    content = [Form.submit(label || "Submit", merge_css_classes(opts)), alternative]
    draw_form_group("", content)
  end

  defp draw_form_check(input, label, is_inline) do
    inline_class = if (is_inline), do: "form-check-inline", else: ""
    Tag.content_tag :div, class: "form-check #{inline_class}" do
      Tag.content_tag :label, class: "form-check-label" do
        [input, "\n", label]
      end
    end
  end

  defp draw_error_message(nil), do: ""
  defp draw_error_message(message) do
    Tag.content_tag :div, message, class: "invalid-feedback"
  end

end
