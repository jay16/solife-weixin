window.Openfind =
  chk_url: (input) ->
    val = $.trim($(input).val())
    url = $.trim($("input[type='hidden'][name='url']").val())
    regstr = "^"+url.replace("//","\\/\\/")
    console.log(regstr)
    regexp = new RegExp(regstr)
    console.log(regexp.test(val))

    if(regexp.test(val))
      $("#warn").html("")
      $("#warn").addClass("hidden")
      $(input).parent().siblings("input[type='submit']").removeAttr("disabled")
    else
      $("#warn").html("输入链接的域名不正确...")
      $("#warn").removeClass("hidden")
      $(input).parent().siblings("input[type='submit']").attr("disabled", "disabled")

$ ->
  $("#memberForm input[name='url']").bind "change keyup input", ->
    Openfind.chk_url(this)
  $("#templateForm input[name='url']").bind "change keyup input", ->
    Openfind.chk_url(this)
