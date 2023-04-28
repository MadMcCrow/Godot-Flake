# custom.nix
# this modules focuses on generating or overriding the custom.py used to build godot
{ lib }:
with lib;
with builtins;
let

  # default Scons options
  # you can get them with : Scons --help
  defaults = {
    arch = "auto";
    dev_build = false;
    optimize = "speed_trace";
    debug_symbols = false;
    separate_debug_symbols = false;
    lto = "none";
    production = false;
    deprecated = true;
    precision = "single";
    minizip = true;
    xaudio2 = false;
    vulkan = true;
    opengl3 = true;
    openxr = true;
    use_volk = true;
    custom_modules = "";
    custom_modules_recursive = true;
    dev_mode = false;
    tests = false;
    fast_unsafe = false;
    compiledb = false;
    verbose = false;
    progress = true;
    warnings = "all";
    werror = false;
    extra_suffix = "";
    vsproj = false;
    vsproj_name = "godot";
    disable_3d = false;
    disable_advanced_gui = false;
    build_profile = "";
    modules_enabled_by_default = true;
    no_editor_splash = true;
    system_certs_path = "";
    use_precise_math_checks = false;
    builtin_certs = true;
    builtin_embree = true;
    builtin_enet = true;
    builtin_freetype = true;
    builtin_msdfgen = true;
    builtin_glslang = true;
    builtin_graphite = true;
    builtin_harfbuzz = true;
    builtin_icu4c = true;
    builtin_libogg = true;
    builtin_libpng = true;
    builtin_libtheora = true;
    builtin_libvorbis = true;
    builtin_libwebp = true;
    builtin_wslay = true;
    builtin_mbedtls = true;
    builtin_miniupnpc = true;
    builtin_pcre2 = true;
    builtin_pcre2_with_jit = true;
    builtin_recastnavigation = true;
    builtin_rvo2 = true;
    builtin_squish = true;
    builtin_xatlas = true;
    builtin_zlib = true;
    builtin_zstd = true;
    CXX = "";
    CC = "";
    LINK = "";
    CCFLAGS = "";
    CFLAGS = "";
    CXXFLAGS = "";
    LINKFLAGS = "";
    linker = "default";
    use_llvm = false;
    use_static_cpp = true;
    use_coverage = false;
    use_ubsan = false;
    use_asan = false;
    use_lsan = false;
    use_tsan = false;
    use_msan = false;
    use_sowrap = true;
    alsa = true;
    pulseaudio = true;
    dbus = true;
    speechd = true;
    fontconfig = true;
    udev = true;
    x11 = true;
    touch = true;
    execinfo = false;
    module_astcenc_enabled = true;
    module_basis_universal_enabled = true;
    module_bmp_enabled = true;
    module_camera_enabled = true;
    module_csg_enabled = true;
    module_cvtt_enabled = true;
    module_dds_enabled = true;
    module_denoise_enabled = true;
    module_enet_enabled = true;
    module_etcpak_enabled = true;
    brotli = true;
    module_freetype_enabled = true;
    module_gdscript_enabled = true;
    module_glslang_enabled = true;
    module_gltf_enabled = true;
    module_gridmap_enabled = true;
    module_hdr_enabled = true;
    module_jpg_enabled = true;
    module_jsonrpc_enabled = true;
    module_lightmapper_rd_enabled = true;
    module_mbedtls_enabled = true;
    module_meshoptimizer_enabled = true;
    module_minimp3_enabled = true;
    module_mobile_vr_enabled = true;
    module_mono_enabled = false;
    module_msdfgen_enabled = true;
    module_multiplayer_enabled = true;
    module_navigation_enabled = true;
    module_noise_enabled = true;
    module_ogg_enabled = true;
    module_openxr_enabled = true;
    module_raycast_enabled = true;
    module_regex_enabled = true;
    module_squish_enabled = true;
    module_svg_enabled = true;
    graphite = true;
    module_text_server_adv_enabled = true;
    module_text_server_fb_enabled = false;
    module_tga_enabled = true;
    module_theora_enabled = true;
    module_tinyexr_enabled = true;
    module_upnp_enabled = true;
    module_vhacd_enabled = true;
    module_vorbis_enabled = true;
    module_webp_enabled = true;
    module_webrtc_enabled = true;
    module_websocket_enabled = true;
    module_webxr_enabled = true;
    module_xatlas_unwrap_enabled = true;
    module_zip_enabled = true;
  };

  customPy = options : if (hasAttr "profile" options) then getAttr "profile" options else "";

  # helper functions :
  condAttr = n: s: d: if hasAttr n s then getAttr n s else d;
  # convert true/false to "yes" "no" for scons
  boolToString = cond: if cond then "yes" else "no";
  # turn option set into scons options
  mkGodotOption = optionSet:
    (lib.mapAttrsToList (k: v:
      if (lib.isBool v) then
        ("${k}=${boolToString v}")
      else if (lib.isString v) then
        ("${k}=${v}")
      else
        "${k}=${toJSON v}") optionSet);
  
in {

  defaultOptions = defaults;

  # resulting scons flag
  mkSconsFlags = options : if ((customPy options)=="")  then (mkGodotOption options) else "profile=${customPy}";

  # get option from godot
  getOption = name: options: condAttr name options (condAttr name defaults "");
}
