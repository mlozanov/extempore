;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Gstreamer library
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define gstlib
  (sys:open-dylib (if (string=? "Linux" (sys:platform))
		      "libgstreamer-0.10.so"
		      (if (string=? "Windows" (sys:platform))
			  (print-error "Where can I find gstreamer on your platform?")
			  (print-error "Where can I find gstreamer on your platform?")))))

(if (not gstlib) (print-error 'Could 'not load 'gstream 'dynamic 'library))

(load "libs/glib.scm")

(bind-alias GstState i32)
(bind-val GST_STATE_VOID_PENDING i32 0)
(bind-val GST_STATE_NULL i32 1)
(bind-val GST_STATE_READY i32 2)
(bind-val GST_STATE_PAUSED i32 3)
(bind-val GST_STATE_PLAYING i32 4)

(bind-alias GstSeekFlags i32)
(bind-val  GST_SEEK_FLAG_NONE		i32 0)
(bind-val  GST_SEEK_FLAG_FLUSH		i32 1)
(bind-val  GST_SEEK_FLAG_ACCURATE	i32 2)
(bind-val  GST_SEEK_FLAG_KEY_UNIT	i32 4)
(bind-val  GST_SEEK_FLAG_SEGMENT	i32 8)

(bind-alias GstSeekType i32)
(bind-val  GST_SEEK_TYPE_NONE		i32 0)
(bind-val  GST_SEEK_TYPE_CUR		i32 1)
(bind-val  GST_SEEK_TYPE_SET		i32 2)
(bind-val  GST_SEEK_TYPE_END		i32 3)

(bind-alias GstFormat i32)
(bind-val  GST_FORMAT_UNDEFINED i32  0 )
(bind-val  GST_FORMAT_DEFAULT   i32  1)
(bind-val  GST_FORMAT_BYTES   	i32  2)
(bind-val  GST_FORMAT_TIME 	i32  3)
(bind-val  GST_FORMAT_BUFFERS	i32  4)
(bind-val  GST_FORMAT_PERCENT	i32  5)

(bind-alias GstMessageType i32)
(bind-val  GST_MESSAGE_UNKNOWN           i32 0)
(bind-val  GST_MESSAGE_EOS               i32 1)
(bind-val  GST_MESSAGE_ERROR             i32 2)
(bind-val  GST_MESSAGE_WARNING           i32 4)
(bind-val  GST_MESSAGE_INFO              i32 8)
(bind-val  GST_MESSAGE_TAG               i32 16)
(bind-val  GST_MESSAGE_BUFFERING         i32 32)
(bind-val  GST_MESSAGE_STATE_CHANGED     i32 64)
(bind-val  GST_MESSAGE_STATE_DIRTY       i32 128)
(bind-val  GST_MESSAGE_STEP_DONE         i32 256)
(bind-val  GST_MESSAGE_CLOCK_PROVIDE     i32 512)
(bind-val  GST_MESSAGE_CLOCK_LOST        i32 1024)
(bind-val  GST_MESSAGE_NEW_CLOCK         i32 2048)
(bind-val  GST_MESSAGE_STRUCTURE_CHANGE  i32 4096)
(bind-val  GST_MESSAGE_STREAM_STATUS     i32 8192)
(bind-val  GST_MESSAGE_APPLICATION       i32 16384)
(bind-val  GST_MESSAGE_ELEMENT           i32 32768)
(bind-val  GST_MESSAGE_SEGMENT_START     i32 65536)
(bind-val  GST_MESSAGE_SEGMENT_DONE      i32 131072)
(bind-val  GST_MESSAGE_DURATION          i32 262144)
(bind-val  GST_MESSAGE_LATENCY           i32 524288)
(bind-val  GST_MESSAGE_ASYNC_START       i32 1048576)
(bind-val  GST_MESSAGE_ASYNC_DONE        i32 2097152)
(bind-val  GST_MESSAGE_REQUEST_STATE     i32 4194304)
(bind-val  GST_MESSAGE_STEP_START        i32 8388608)
(bind-val  GST_MESSAGE_QOS               i32 16777216)
(bind-val  GST_MESSAGE_PROGRESS          i32 33554432)

(bind-alias GstPadLinkReturn i32)
(bind-val  GST_PAD_LINK_OK               i32  0)
(bind-val  GST_PAD_LINK_WRONG_HIERARCHY  i32 -1)
(bind-val  GST_PAD_LINK_WAS_LINKED       i32 -2)
(bind-val  GST_PAD_LINK_WRONG_DIRECTION  i32 -3)
(bind-val  GST_PAD_LINK_NOFORMAT         i32 -4)
(bind-val  GST_PAD_LINK_NOSCHED          i32 -5)
(bind-val  GST_PAD_LINK_REFUSED          i32 -6)

(bind-alias GstStateChange i32) ;; enum
(bind-alias GstStateChangeReturn i32) ;; enum

(bind-alias GCond i8) ;; not really i8
(bind-alias GStaticRecMutex i8) ;; not really i8
(bind-alias GstBus i8) ;; not really i8
(bind-alias GstClock i8) ;; not really i8
(bind-alias GstClockTimeDiff i64)
(bind-alias GstElementFactory i8) ;; opaque struct
(bind-alias GstPipeline i8) ;; opaque struct
(bind-alias GstBin i8) ;; opaque struct
(bind-alias GstPad i8) ;; opaque struct
(bind-alias GstObject i8) ;; opaque struct
(bind-alias GstEvent i8) ;; opaque struct

(bind-type GstElement <GStaticRecMutex*,GCond*,guint32,GstState,GstState,GstState,GstStateChangeReturn,GstBus*,GstClock*,GstClockTimeDiff,guint16,GList,guint16,GList,guint16,GList,guint32>)
(bind-type GstElementDetails <gchar*,gchar*,gchar*,gchar*>)
(bind-type GstStructure <GType>)
(bind-type GstObject <gint,GMutex*,gchar*,gchar*,GstObject*,guint32>)
(bind-type GstMiniObject <GTypeInstance,i32,i32,i8*>)
;; 3 message type
;; 4 time
;; 5 gst_object
;; 6 gst_structure
;;
;; I add the i32 padding at the END because sizeof reports 104 (I Don't know why!)
(bind-type GstMessage <GstMiniObject,GMutex*,GCond*,GstMessageType,guint64,GstObject*,GstStructure*,|4,gpointer|,i32>)

;; gst object stuff
(bind-lib gstlib gst_object_get_type [GType]*)
(bind-lib gstlib gst_object_ref [gpointer,gpointer]*)
(bind-lib gstlib gst_object_unref [void,gpointer]*)
(bind-lib gstlib gst_object_ref_sink [void,gpointer]*)
(bind-lib gstlib gst_object_sink [void,gpointer]*)

(bind-lib gstlib gst_init [void,i32*,i8**]*)
(bind-lib gstlib gst_init_check [gboolean,i32*,i8**,GError**]*)
(bind-lib gstlib gst_is_initialized [gboolean]*)
(bind-lib gstlib gst_deinit [void]*)
(bind-lib gstlib gst_version [void,i32*,i32*,i32*,i32*]*)
(bind-lib gstlib gst_element_factory_make [GstElement*,gchar*,gchar*]*)
(bind-lib gstlib gst_element_factory_create [GstElement*,GstElementFactory*,gchar*]*)
(bind-lib gstlib gst_element_factory_find [GstElementFactory*,gchar*]*)

;; pipeline 
(bind-lib gstlib gst_pipeline_new [GstElement*,gchar*]*)
(bind-lib gstlib gst_pipeline_get_bus [GstBus*,GstPipeline*]*)
(bind-lib gstlib gst_pipeline_set_clock [gboolean,GstPipeline*,GstClock*]*)

;; elements
(bind-lib gstlib gst_element_link [gboolean,GstElement*,GstElement*]*)
(bind-lib gstlib gst_element_unlink [void,GstElement*,GstElement*]*)
(bind-lib gstlib gst_element_add_pad [gboolean,GstElement*,GstPad*]*)
(bind-lib gstlib gst_element_get_pad [GstPad*,GstElement*,gchar*]*)
(bind-lib gstlib gst_element_set_state [GstStateChangeReturn,GstElement*,GstState]*)
(bind-lib gstlib gst_element_get_static_pad [GstPad*,GstElement*,gchar*]*)

;; bins
(bind-lib gstlib gst_bin_add [gboolean,GstBin*,GstElement*]*)
(bind-lib gstlib gst_bin_remove [gboolean,GstBin*,GstElement*]*)
(bind-lib gstlib gst_bin_get_by_name [GstElement*,GstBin*,gchar*]*)

;; buss
(bind-alias GstBusSyncReply i32) ;; enum
(bind-alias GstBusFunc [gboolean,GstBus*,GstMessage*,gpointer]*)
(bind-alias GstBusSyncHandler [GstBusSyncReply,GstBus*,GstMessage*,gpointer]*)

(bind-lib gstlib gst_bus_new [GstBus*]*)
(bind-lib gstlib gst_bus_post [gboolean,GstBus*,GstMessage*]*)
(bind-lib gstlib gst_bus_add_watch [guint,GstBus*,GstBusFunc,gpointer]*)

;; pads
(bind-lib gstlib gst_pad_link [GstPadLinkReturn,GstPad*,GstPad*]*)
(bind-lib gstlib gst_pad_unlink [gboolean,GstPad*,GstPad*]*)

;; events
(bind-lib gstlib gst_event_new_seek [GstEvent*,gdouble,GstFormat,GstSeekFlags,GstSeekType,gint64,GstSeekType,gint64]*)

;; messages
(bind-lib gstlib gst_message_parse_error [void,GstMessage*,GError**,gchar**]*)
(bind-lib gstlib gst_message_new_eos [GstMessage*,GstObject*]*)
