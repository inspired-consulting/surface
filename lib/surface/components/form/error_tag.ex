defmodule Surface.Components.Form.ErrorTag do
  @moduledoc """
  A component inspired by `error_tag/3` that ships with `mix phx.new` in
  `MyAppWeb.ErrorHelpers`.

  Renders error messages if any exist regarding the given field.

  ## Error Translation

  Changeset errors are translated using the default error translator
  that ships with phoenix when generated with `mix phx.new --no-gettext`.

  When using Gettext, you can use configuration to route all errors through
  the `MyAppWeb.ErrorHelpers.translate_error/1` function generated by Phoenix,
  which utilizes `Gettext`. You need to provide a tuple with the module and
  the name of the function (as an atom) as follows:

  ```elixir
  config :surface, :components, [
    {Surface.Components.Form.ErrorTag, default_translator: {MyAppWeb.ErrorHelpers, :translate_error}}
  ]
  ```

  There is also a `translator` prop which can be used on a case-by-case basis.
  It overrides the configuration.

  ## Examples

  ```surface
  <ErrorTag field="password" />
  ```

  ```surface
  <Field name="password">
    <ErrorTag />
  </Field>
  ```

  ```surface
  <ErrorTag feedback_for="confirm_password_for_reset" />
  ```

  ```surface
  <ErrorTag class="custom-css-classes" />
  ```

  ```surface
  <ErrorTag translator={{ &CustomTranslationLib.translate_error/1 }} />
  ```
  """

  use Surface.Component

  import Phoenix.HTML.Form, only: [input_id: 2]

  alias Surface.Components.Form.Input.InputContext

  @doc "An identifier for the form"
  prop form, :form

  @doc "An identifier for the associated field"
  prop field, :any

  @doc """
  Classes to apply to each error tag <span>.

  This can also be set via config, for example:

  ```elixir
  config :surface, :components, [
    {Surface.Components.Form.ErrorTag, default_class: "invalid-feedback"}
  ]
  ```

  However, the prop overrides the config value if provided.
  """
  prop class, :css_class

  @doc """
  A function that takes one argument `{msg, opts}` and returns
  the translated error message as a string. If not provided, falls
  back to Phoenix's default implementation.

  This can also be set via config, for example:

  ```elixir
  config :surface, :components, [
    {Surface.Components.Form.ErrorTag, default_translator: {MyApp.Gettext, :translate_error}}
  ]
  ```
  """
  prop translator, :fun

  @doc """
  If you changed the default ID on the input, provide it here.
  (Useful when there are multiple forms on the same page, each
  with an input of the same name. LiveView will exhibit buggy behavior
  without assigning separate id's to each.)
  """
  prop feedback_for, :string

  def render(assigns) do
    translate_error = assigns.translator || translator_from_config() || (&translate_error/1)
    class = assigns.class || get_config(:default_class)

    ~H"""
    <InputContext assigns={assigns} :let={form: form, field: field}>
      <span
        :for={error <- Keyword.get_values(form.errors, field)}
        class={class}
        phx-feedback-for={@feedback_for || input_id(form, field)}
      >{translate_error.(error)}</span>
    </InputContext>
    """
  end

  @doc """
  Translates an error message.

  This is the fallback (Phoenix's default implementation) if a translator
  is not provided via config or the `translate` prop.
  """
  def translate_error({msg, opts}) do
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp translator_from_config do
    case get_config(:default_translator) do
      {module, function} -> &apply(module, function, [&1])
      nil -> nil
    end
  end
end
